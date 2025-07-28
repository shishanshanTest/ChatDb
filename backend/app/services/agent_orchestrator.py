"""
智能体编排服务
负责协调和管理所有智能体的执行流程
"""
from typing import Optional

from autogen_core import SingleThreadedAgentRuntime, DefaultTopicId

from app.core.config import settings
from app.db.dbaccess import DBAccess
from app.db.session import SessionLocal
from app.schemas.text2sql import QueryMessage, ResponseMessage
from app.agents.base import StreamResponseCollector
from app.agents.factory import AgentFactory
from app.agents.types import TopicTypes, DEFAULT_DB_TYPE
from app import crud


class AgentOrchestrator:
    """智能体编排服务，处理自然语言到SQL转换的全流程"""

    def __init__(self):
        """初始化智能体编排服务"""
        self.db_type = DEFAULT_DB_TYPE
        self.db = None
        self.db_access = None

    def _get_connection_info(self, connection_id: int):
        """根据连接ID获取数据库连接信息和类型

        Args:
            connection_id: 数据库连接ID

        Returns:
            DBConnection: 数据库连接信息
        """
        connection_info = None
        try:
            if not self.db:
                self.db = SessionLocal()
            connection_info = crud.db_connection.get(db=self.db, id=connection_id)
        except Exception as e:
            print(f"获取数据库连接信息时出错: {str(e)}")
        finally:
            if self.db:
                self.db.close()
                self.db = None

        return connection_info

    def _setup_database_connection(self, connection_id: Optional[int] = None) -> DBAccess:
        """设置数据库连接

        Args:
            connection_id: 数据库连接ID，可选

        Returns:
            DBAccess: 数据库访问对象（确保不为None）
        """
        db_access = None

        if connection_id:
            # 获取连接信息和数据库类型
            connection_info = self._get_connection_info(connection_id)
            if connection_info:
                print(f"[连接ID: {connection_id}] 数据库类型: {connection_info.db_type}")
                self.db_type = connection_info.db_type

                try:
                    db_access = DBAccess()
                    # 根据数据库类型创建连接
                    if connection_info.db_type.lower() == "mysql":
                        db_access.connect_to_mysql(
                            host=connection_info.host,
                            dbname=connection_info.database_name,
                            user=connection_info.username,
                            password=connection_info.password_encrypted,
                            port=connection_info.port
                        )
                    elif connection_info.db_type.lower() == "postgresql":
                        db_access.connect_to_postgres(
                            host=connection_info.host,
                            dbname=connection_info.database_name,
                            user=connection_info.username,
                            password=connection_info.password_encrypted,
                            port=connection_info.port
                        )
                    elif connection_info.db_type.lower() == "sqlite":
                        db_access.connect_to_sqlite(connection_info.database_name)
                    else:
                        print(f"不支持的数据库类型: {connection_info.db_type}，创建默认连接")
                        db_access = self._create_default_db_access()
                except Exception as e:
                    print(f"创建数据库连接时出错: {str(e)}，创建默认连接")
                    db_access = self._create_default_db_access()

        # 如果没有connection_id或创建失败，确保返回一个有效的DBAccess对象
        if db_access is None:
            print("创建默认数据库连接")
            db_access = self._create_default_db_access()

        return db_access

    def _create_default_db_access(self) -> DBAccess:
        """创建一个有效的默认数据库连接对象

        Returns:
            DBAccess: 配置了默认run_sql方法的数据库访问对象
        """
        db_access = DBAccess()

        # 设置一个默认的run_sql方法，返回错误信息而不是崩溃
        def default_run_sql(sql: str):
            raise Exception("数据库连接未正确配置。请检查数据库连接设置。")

        db_access.run_sql = default_run_sql
        db_access.run_sql_is_set = True

        return db_access

    async def process_query(self, query: str, collector: StreamResponseCollector = None,
                          connection_id: Optional[int] = None, user_feedback_enabled: bool = False):
        """处理自然语言查询，返回SQL和结果

        Args:
            query: 自然语言查询
            collector: 流式响应收集器
            connection_id: 数据库连接ID，可选
            user_feedback_enabled: 是否启用用户反馈功能
        """
        # 如果没有提供收集器，创建一个默认的
        if not collector:
            collector = StreamResponseCollector()

        # 设置数据库连接
        db_access = self._setup_database_connection(connection_id)
        self.db_access = db_access

        try:
            # 创建运行时
            runtime = SingleThreadedAgentRuntime()

            # 创建智能体工厂并注册所有智能体
            factory = AgentFactory(db_type=self.db_type, db_access=self.db_access)
            await factory.register_all_agents(runtime, collector, user_feedback_enabled=user_feedback_enabled)

            # 启动运行时
            runtime.start()

            # 发送初始消息
            message = QueryMessage(
                query=query,
                connection_id=connection_id
            )

            # 发送到表结构检索智能体
            await runtime.publish_message(
                message,
                topic_id=DefaultTopicId(type=TopicTypes.SCHEMA_RETRIEVER.value)
            )

            # 等待处理完成
            await runtime.stop_when_idle()

            # 关闭运行时
            await runtime.close()

            # 确保所有缓冲消息都被发送
            if hasattr(collector, 'flush_all_buffers'):
                await collector.flush_all_buffers()

        except Exception as e:
            print(f"处理查询时发生错误: {str(e)}")
            if collector and collector.callback:
                # 发送错误消息
                await collector.callback(None, ResponseMessage(
                    source="系统",
                    content=f"处理查询时发生错误: {str(e)}",
                    is_final=True
                ), None)

# ChatDB - 智能文本转SQL系统

ChatDB是一个智能的文本转SQL系统，允许用户使用自然语言查询数据库。该系统具有用于模式可视化和管理的React前端、用于处理查询的Python FastAPI后端，并使用MySQL和Neo4j进行元数据存储和模式关系管理。

## 功能特性

- **数据库连接管理**: 连接到各种数据库系统
- **模式可视化与管理**: 通过交互式图形界面可视化和维护数据库模式
- **智能查询**: 使用LLM技术将自然语言问题转换为SQL查询
- **值映射**: 将自然语言术语映射到实际数据库值

## 系统架构

- **前端**: React + Ant Design + React Flow 可视化
- **后端**: Python FastAPI
- **元数据存储**: MySQL
- **模式关系存储**: Neo4j
- **LLM集成**: OpenAI GPT-4 (或其他LLM服务)

## 环境要求

- Docker 和 Docker Compose
- OpenAI API密钥 (或其他LLM服务API密钥)

## 安装和配置

1. 克隆仓库:
   ```
   git clone https://github.com/yourusername/chatdb.git
   cd chatdb
   ```

2. 在根目录创建 `.env` 文件并配置OpenAI API密钥:
   ```
   OPENAI_API_KEY=your_openai_api_key_here
   ```

3. 使用Docker Compose启动服务:
   ```
   docker-compose up -d
   ```

4. 初始化数据库 (仅首次运行):
   ```
   docker-compose exec backend python init_db.py
   ```

5. 访问应用程序:
   - 前端界面: http://localhost:3000
   - 后端API文档: http://localhost:8000/docs
   - Neo4j浏览器: http://localhost:7474 (用户名: neo4j, 密码: password)

## 使用指南

### 1. 数据库连接

1. 导航到"连接管理"页面
2. 点击"添加连接"创建新的数据库连接
3. 填写连接详细信息并点击"保存"
4. 使用"测试"按钮测试连接

### 2. 数据建模

1. 导航到"数据建模"页面
2. 从下拉菜单中选择数据库连接
3. 系统将从目标数据库中发现模式
4. 从左侧面板将表拖拽到画布上
5. 通过从一个表拖拽到另一个表来连接表
6. 点击表或关系来编辑它们的属性
7. 点击"发布模式"保存更改

### 3. 智能查询

1. 导航到"智能查询"页面
2. 从下拉菜单中选择数据库连接
3. 用自然语言输入您的问题
4. 点击"执行查询"生成并运行SQL
5. 查看生成的SQL、查询结果和上下文信息

### 4. 数据映射

1. 导航到"数据映射"页面
2. 选择连接、表和列
3. 添加自然语言术语与数据库值之间的映射
4. 这些映射将在处理自然语言查询时使用

## 开发指南

### 后端开发

后端使用FastAPI构建，并使用SQLAlchemy进行数据库ORM。

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

### 前端开发

前端使用React构建，并使用Ant Design作为UI组件。

```bash
cd frontend
npm install
npm start
```


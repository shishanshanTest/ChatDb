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

2. 在根目录创建 `.env` 文件并配置必要参数:
   ```bash
   # 复制示例配置文件
   cp .env.example .env

   # 编辑配置文件，填入实际值
   # SERVER_IP=your_vultr_server_ip
   # OPENAI_API_KEY=your_openai_api_key_here
   ```

3. 部署应用 (推荐使用部署脚本):
   ```bash
   # 使用自动化部署脚本
   ./scripts/deploy.sh

   # 或手动部署
   docker-compose up -d
   sleep 60
   docker-compose exec backend python init_db.py
   ```

4. 验证部署:
   ```bash
   # 运行健康检查
   ./scripts/health_check.sh
   ```

5. 访问应用程序:
   - 前端界面: http://your_server_ip:3000
   - 后端API文档: http://your_server_ip:8000/docs
   - 管理界面通过SSH隧道访问 (安全考虑)

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

## 生产环境部署 (Vultr)

### 服务器要求
- **最低配置**: 4GB RAM, 2 CPU, 80GB SSD
- **推荐配置**: 8GB RAM, 4 CPU, 160GB SSD
- **操作系统**: Ubuntu 22.04 LTS

### 部署步骤

1. **服务器初始化**:
   ```bash
   # 更新系统
   sudo apt update && sudo apt upgrade -y

   # 安装Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh

   # 安装Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

2. **配置防火墙**:
   ```bash
   sudo ufw enable
   sudo ufw allow ssh
   sudo ufw allow 3000
   sudo ufw allow 8000
   ```

3. **部署应用**:
   ```bash
   git clone <your-repo-url>
   cd chatdb
   cp .env.example .env
   # 编辑.env文件，填入服务器IP和API密钥
   ./scripts/deploy.sh
   ```

### 访问应用

部署完成后，可以通过以下地址访问：
- **前端界面**: http://your_server_ip:3000
- **后端API文档**: http://your_server_ip:8000/docs

### 可选优化

如需要域名访问或HTTPS，可以考虑：
- 使用Caddy服务器（配置更简单）
- 使用Vultr负载均衡器
- 将前端端口改为80端口（需要root权限）


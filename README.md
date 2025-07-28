# ChatDB - 智能文本转SQL系统

ChatDB是一个智能的文本转SQL系统，允许用户使用自然语言查询数据库。该系统具有用于模式可视化和管理的React前端、用于处理查询的Python FastAPI后端，并使用MySQL和Neo4j进行元数据存储和模式关系管理。

## 功能特性

- **数据库连接管理**: 连接到各种数据库系统
- **模式可视化与管理**: 通过交互式图形界面可视化和维护数据库模式
- **智能查询**: 使用LLM技术将自然语言问题转换为SQL查询
- **值映射**: 将自然语言术语映射到实际数据库值

## 系统架构

- **前端**: React + Ant Design + React Flow 可视化
- **后端**: Python 3.10 + FastAPI
- **元数据存储**: MySQL
- **模式关系存储**: Neo4j
- **向量数据库**: Milvus
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

## Vultr服务器手动部署指南

### 🖥️ 服务器要求
- **最低配置**: 4GB RAM, 2 CPU, 80GB SSD
- **推荐配置**: 8GB RAM, 4 CPU, 160GB SSD
- **操作系统**: Ubuntu 22.04 LTS

### 📋 部署前准备

#### 1. 服务器初始化
```bash
# 连接服务器
ssh root@your_vultr_server_ip

# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础工具
sudo apt install -y curl wget git vim htop unzip

# 创建非root用户（推荐）
adduser chatdb
usermod -aG sudo chatdb
su - chatdb
```

#### 2. 安装Docker环境
```bash
# 安装Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 将用户添加到docker组
sudo usermod -aG docker $USER

# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 重新登录以应用组权限
exit
ssh chatdb@your_vultr_server_ip
```

#### 3. 验证安装
```bash
# 验证Docker
docker --version
docker run hello-world

# 验证Docker Compose
docker-compose --version
```

#### 4. 配置防火墙
```bash
# 启用防火墙
sudo ufw enable

# 允许必要端口
sudo ufw allow ssh
sudo ufw allow 3000/tcp
sudo ufw allow 8000/tcp

# 检查状态
sudo ufw status
```

### 🚀 应用部署步骤

#### 1. 获取项目代码
```bash
# 克隆项目（替换为实际仓库地址）
git clone https://github.com/your-username/chatdb.git
cd chatdb

# 或者上传项目文件
# scp -r ./chatdb chatdb@your_vultr_server_ip:/home/chatdb/
```

#### 2. 配置环境变量

**配置Docker Compose环境变量**：
```bash
# 复制Docker Compose配置文件
cp .env.example .env

# 编辑配置文件，设置服务器IP
vim .env
```

**必须配置的内容**：
```bash
# 设置服务器IP地址（用于前端API配置）
SERVER_IP=your_vultr_server_ip
```

**配置后端应用环境变量**：
```bash
# 复制后端配置文件
cp backend/.env.example backend/.env

# 编辑后端配置文件
vim backend/.env
```

**必须配置的内容**：
```bash
# 设置OpenAI API密钥
OPENAI_API_KEY=your_actual_openai_api_key

# 如使用DeepSeek等其他服务，修改：
# OPENAI_API_BASE=https://api.deepseek.com/v1
# LLM_MODEL=deepseek-chat

# 其他配置项通常使用默认值即可
```

#### 3. 检查配置文件
```bash
# 验证必要文件存在
ls -la .env docker-compose.yml backend/.env

# 检查Docker Compose配置（确保SERVER_IP已设置）
cat .env

# 检查后端配置（确保API密钥已设置）
cat backend/.env | grep OPENAI_API_KEY
```

#### 4. 停止现有服务（如果有）
```bash
# 停止可能运行的服务
docker-compose down || true

# 清理旧容器和镜像（可选）
docker system prune -f
```

#### 5. 构建Docker镜像
```bash
# 构建所有服务的镜像
docker-compose build --no-cache

# 检查构建结果
docker images | grep chatdb
```

#### 6. 启动服务
```bash
# 启动所有服务
docker-compose up -d

# 检查服务状态
docker-compose ps
```

#### 7. 等待服务启动
```bash
# 等待服务完全启动（重要！）
echo "等待服务启动..."
sleep 60

# 检查容器日志
docker-compose logs --tail=20
```

#### 8. 初始化数据库
```bash
# 初始化数据库结构
docker-compose exec backend python init_db.py

# 验证数据库连接
docker-compose exec mysql mysql -u root -ppassword -e "SHOW DATABASES;"
```

### ✅ 部署验证

#### 1. 检查服务状态
```bash
# 查看所有容器状态
docker-compose ps

# 查看服务日志
docker-compose logs frontend
docker-compose logs backend
docker-compose logs mysql
docker-compose logs neo4j
docker-compose logs milvus
```

#### 2. 测试网络连接
```bash
# 测试前端
curl -I http://localhost:3000

# 测试后端API
curl -I http://localhost:8000/docs

# 从外网测试（替换为实际IP）
curl -I http://your_vultr_server_ip:3000
curl -I http://your_vultr_server_ip:8000/docs
```

#### 3. 测试数据库连接
```bash
# 测试MySQL
docker-compose exec mysql mysql -u root -ppassword -e "SELECT 1;"

# 测试Neo4j
docker-compose exec neo4j cypher-shell -u neo4j -p password "RETURN 1;"

# 测试Milvus
curl -s http://localhost:9091/health
```

### 📋 配置文件说明

本项目使用两个配置文件：

1. **根目录 `.env`** - Docker Compose配置
   - 用途：Docker Compose的变量替换
   - 主要配置：`SERVER_IP`（前端API地址配置）
   - 示例：`.env.example`

2. **backend/.env** - 后端应用配置
   - 用途：后端Python应用直接读取
   - 主要配置：OpenAI API密钥、数据库连接、模型参数等
   - 示例：`backend/.env.example`

**重要**：两个配置文件都必须正确配置，缺一不可。

### 🌐 访问应用

部署成功后，通过以下地址访问：
- **前端界面**: `http://your_vultr_server_ip:3000`
- **后端API文档**: `http://your_vultr_server_ip:8000/docs`

### 🚨 故障排查

#### 常见问题及解决方案

1. **容器启动失败**
```bash
# 查看详细日志
docker-compose logs [service_name]

# 重启特定服务
docker-compose restart [service_name]

# 重新构建并启动
docker-compose down
docker-compose build --no-cache [service_name]
docker-compose up -d
```

2. **端口无法访问**
```bash
# 检查端口占用
sudo netstat -tlnp | grep :3000
sudo netstat -tlnp | grep :8000

# 检查防火墙
sudo ufw status

# 检查容器端口映射
docker-compose ps
```

3. **数据库连接失败**
```bash
# 检查数据库容器状态
docker-compose ps mysql neo4j

# 重启数据库服务
docker-compose restart mysql neo4j

# 检查数据库日志
docker-compose logs mysql
docker-compose logs neo4j
```

4. **API密钥问题**
```bash
# 检查后端配置文件
cat backend/.env | grep OPENAI_API_KEY

# 重新设置API密钥
vim backend/.env
docker-compose restart backend

# 验证配置是否生效
docker-compose exec backend python -c "
from app.core.config import settings
print('API Key configured:', bool(settings.OPENAI_API_KEY))
"
```

### 🔧 维护操作

#### 更新应用
```bash
# 拉取最新代码
git pull origin main

# 重新构建和部署
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# 验证更新
docker-compose ps
```

#### 备份数据
```bash
# 备份MySQL数据
docker-compose exec mysql mysqldump -u root -ppassword chatdb > backup_$(date +%Y%m%d).sql

# 备份Neo4j数据
docker-compose exec neo4j neo4j-admin dump --database=neo4j --to=/data/backup_$(date +%Y%m%d).dump
```

#### 查看资源使用
```bash
# 查看容器资源使用
docker stats

# 查看系统资源
htop
df -h
```


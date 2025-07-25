# ChatDB Vultr服务器部署指南

## 项目架构概述

ChatDB是一个智能Text2SQL系统，包含以下组件：
- **前端**: React + TypeScript + Ant Design + React Flow
- **后端**: Python FastAPI + SQLAlchemy + Pydantic
- **数据库**: MySQL (元数据存储) + Neo4j (图数据库) + Milvus (向量数据库)
- **AI服务**: OpenAI GPT-4 / DeepSeek API
- **容器化**: Docker + Docker Compose

## 服务器环境要求

### 最低配置
- **CPU**: 4核心
- **内存**: 8GB RAM
- **存储**: 100GB SSD
- **操作系统**: Ubuntu 20.04 LTS 或更高版本
- **网络**: 公网IP，开放端口 80, 443, 3000, 8000

### 推荐配置
- **CPU**: 8核心
- **内存**: 16GB RAM
- **存储**: 200GB SSD
- **操作系统**: Ubuntu 22.04 LTS

## 1. 服务器初始化配置

### 1.1 创建Vultr服务器实例
```bash
# 选择配置
- 地区: 选择离用户最近的数据中心
- 操作系统: Ubuntu 22.04 LTS
- 服务器大小: 至少 4GB RAM / 2 CPU
- 启用IPv6: 可选
- 自动备份: 建议启用
```

### 1.2 连接服务器并更新系统
```bash
# SSH连接服务器
ssh root@your_server_ip

# 更新系统包
apt update && apt upgrade -y

# 安装基础工具
apt install -y curl wget git vim htop unzip software-properties-common
```

### 1.3 创建非root用户
```bash
# 创建用户
adduser chatdb
usermod -aG sudo chatdb

# 配置SSH密钥（可选）
mkdir -p /home/chatdb/.ssh
cp ~/.ssh/authorized_keys /home/chatdb/.ssh/
chown -R chatdb:chatdb /home/chatdb/.ssh
chmod 700 /home/chatdb/.ssh
chmod 600 /home/chatdb/.ssh/authorized_keys
```

## 2. 安装Docker和Docker Compose

### 2.1 安装Docker
```bash
# 切换到chatdb用户
su - chatdb

# 安装Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 将用户添加到docker组
sudo usermod -aG docker chatdb

# 重新登录以应用组权限
exit
su - chatdb

# 验证Docker安装
docker --version
```

### 2.2 安装Docker Compose
```bash
# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
docker-compose --version
```

## 3. 部署ChatDB应用

### 3.1 克隆项目代码
```bash
# 克隆项目
git clone https://github.com/your-username/chatdb.git
cd chatdb

# 或者上传项目文件到服务器
# scp -r ./chatdb chatdb@your_server_ip:/home/chatdb/
```

### 3.2 配置环境变量
```bash
# 创建环境配置文件
cat > .env << EOF
# OpenAI API配置
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_API_BASE=https://api.openai.com/v1
LLM_MODEL=gpt-4

# 或者使用DeepSeek API
# OPENAI_API_KEY=your_deepseek_api_key
# OPENAI_API_BASE=https://api.deepseek.com/v1
# LLM_MODEL=deepseek-chat

# 数据库配置
MYSQL_ROOT_PASSWORD=your_secure_mysql_password
MYSQL_DATABASE=chatdb
MYSQL_USER=root
MYSQL_PASSWORD=your_secure_mysql_password

# Neo4j配置
NEO4J_AUTH=neo4j/your_secure_neo4j_password

# 应用配置
SECRET_KEY=your_very_secure_secret_key_here
EOF

# 设置文件权限
chmod 600 .env
```

### 3.3 修改Docker Compose配置（生产环境）
```bash
# 备份原配置
cp docker-compose.yml docker-compose.yml.backup

# 编辑生产环境配置
cat > docker-compose.prod.yml << EOF
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: chatdb-mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: \${MYSQL_DATABASE}
    ports:
      - "127.0.0.1:3306:3306"  # 只绑定本地
    volumes:
      - mysql_data:/var/lib/mysql
      - ./mysql/conf.d:/etc/mysql/conf.d
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci

  neo4j:
    image: neo4j:4.4
    container_name: chatdb-neo4j
    restart: always
    environment:
      NEO4J_AUTH: \${NEO4J_AUTH}
    ports:
      - "127.0.0.1:7474:7474"  # 只绑定本地
      - "127.0.0.1:7687:7687"  # 只绑定本地
    volumes:
      - neo4j_data:/data
      - neo4j_logs:/logs

  backend:
    build: ./backend
    container_name: chatdb-backend
    restart: always
    depends_on:
      - mysql
      - neo4j
    environment:
      - MYSQL_SERVER=mysql
      - MYSQL_USER=\${MYSQL_USER}
      - MYSQL_PASSWORD=\${MYSQL_PASSWORD}
      - MYSQL_DB=\${MYSQL_DATABASE}
      - MYSQL_PORT=3306
      - NEO4J_URI=bolt://neo4j:7687
      - NEO4J_USER=neo4j
      - NEO4J_PASSWORD=\${NEO4J_AUTH#*/}
      - OPENAI_API_KEY=\${OPENAI_API_KEY}
      - OPENAI_API_BASE=\${OPENAI_API_BASE}
      - LLM_MODEL=\${LLM_MODEL}
      - SECRET_KEY=\${SECRET_KEY}
    ports:
      - "127.0.0.1:8000:8000"  # 只绑定本地
    volumes:
      - ./backend:/app

  frontend:
    build: 
      context: ./frontend
      dockerfile: Dockerfile.prod
    container_name: chatdb-frontend
    restart: always
    depends_on:
      - backend
    environment:
      - REACT_APP_API_URL=https://your-domain.com/api
    ports:
      - "127.0.0.1:3000:80"  # 只绑定本地
    volumes:
      - ./frontend/nginx.conf:/etc/nginx/nginx.conf

volumes:
  mysql_data:
  neo4j_data:
  neo4j_logs:
EOF
```

## 4. 配置前端生产构建

### 4.1 创建前端生产Dockerfile
```bash
cat > frontend/Dockerfile.prod << EOF
# 构建阶段
FROM node:16-alpine as build

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --only=production

COPY . .
RUN npm run build

# 生产阶段
FROM nginx:alpine

# 复制构建文件
COPY --from=build /app/build /usr/share/nginx/html

# 复制nginx配置
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF
```

### 4.2 创建Nginx配置
```bash
cat > frontend/nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  localhost;
        root   /usr/share/nginx/html;
        index  index.html index.htm;

        # 处理React Router
        location / {
            try_files \$uri \$uri/ /index.html;
        }

        # API代理
        location /api/ {
            proxy_pass http://backend:8000/api/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # 静态文件缓存
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
EOF
```

## 5. 启动应用服务

### 5.1 构建和启动服务
```bash
# 构建镜像
docker-compose -f docker-compose.prod.yml build

# 启动服务
docker-compose -f docker-compose.prod.yml up -d

# 查看服务状态
docker-compose -f docker-compose.prod.yml ps

# 查看日志
docker-compose -f docker-compose.prod.yml logs -f
```

### 5.2 初始化数据库
```bash
# 等待MySQL启动完成（约30秒）
sleep 30

# 初始化数据库
docker-compose -f docker-compose.prod.yml exec backend python init_db.py

# 验证数据库连接
docker-compose -f docker-compose.prod.yml exec backend python -c "
from app.db.session import SessionLocal
db = SessionLocal()
print('Database connection successful!')
db.close()
"
```

## 6. 配置反向代理和SSL

### 6.1 安装Nginx
```bash
# 安装Nginx
sudo apt install -y nginx

# 启动并启用Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 6.2 配置Nginx反向代理
```bash
# 创建站点配置
sudo cat > /etc/nginx/sites-available/chatdb << EOF
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    # 重定向到HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;

    # SSL配置（稍后配置）
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    # 前端
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # 后端API
    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # WebSocket支持
    location /ws/ {
        proxy_pass http://127.0.0.1:8000/ws/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# 启用站点
sudo ln -s /etc/nginx/sites-available/chatdb /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 6.3 配置SSL证书（Let's Encrypt）
```bash
# 安装Certbot
sudo apt install -y certbot python3-certbot-nginx

# 获取SSL证书
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# 设置自动续期
sudo crontab -e
# 添加以下行：
# 0 12 * * * /usr/bin/certbot renew --quiet
```

## 7. 配置防火墙

### 7.1 配置UFW防火墙
```bash
# 启用UFW
sudo ufw enable

# 允许SSH
sudo ufw allow ssh

# 允许HTTP和HTTPS
sudo ufw allow 80
sudo ufw allow 443

# 查看状态
sudo ufw status
```

## 8. 监控和日志配置

### 8.1 配置日志轮转
```bash
# 创建日志轮转配置
sudo cat > /etc/logrotate.d/chatdb << EOF
/var/log/nginx/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        systemctl reload nginx
    endscript
}
EOF
```

### 8.2 设置系统监控
```bash
# 安装htop和iotop
sudo apt install -y htop iotop

# 创建监控脚本
cat > ~/monitor.sh << EOF
#!/bin/bash
echo "=== System Status ==="
date
echo "=== CPU and Memory ==="
free -h
echo "=== Disk Usage ==="
df -h
echo "=== Docker Containers ==="
docker ps
echo "=== Application Logs (last 10 lines) ==="
docker-compose -f docker-compose.prod.yml logs --tail=10
EOF

chmod +x ~/monitor.sh
```

## 9. 备份策略

### 9.1 数据库备份脚本
```bash
cat > ~/backup.sh << EOF
#!/bin/bash
BACKUP_DIR="/home/chatdb/backups"
DATE=\$(date +%Y%m%d_%H%M%S)

mkdir -p \$BACKUP_DIR

# MySQL备份
docker exec chatdb-mysql mysqldump -u root -p\${MYSQL_ROOT_PASSWORD} chatdb > \$BACKUP_DIR/mysql_\$DATE.sql

# Neo4j备份
docker exec chatdb-neo4j neo4j-admin dump --database=neo4j --to=/data/neo4j_\$DATE.dump
docker cp chatdb-neo4j:/data/neo4j_\$DATE.dump \$BACKUP_DIR/

# 压缩备份
tar -czf \$BACKUP_DIR/chatdb_backup_\$DATE.tar.gz \$BACKUP_DIR/*_\$DATE.*

# 清理7天前的备份
find \$BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: chatdb_backup_\$DATE.tar.gz"
EOF

chmod +x ~/backup.sh

# 设置定时备份
crontab -e
# 添加以下行（每天凌晨2点备份）：
# 0 2 * * * /home/chatdb/backup.sh
```

## 10. 故障排除指南

### 10.1 常见问题诊断
```bash
# 检查服务状态
docker-compose -f docker-compose.prod.yml ps

# 查看服务日志
docker-compose -f docker-compose.prod.yml logs [service_name]

# 检查端口占用
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# 检查Nginx配置
sudo nginx -t

# 重启服务
docker-compose -f docker-compose.prod.yml restart [service_name]
```

### 10.2 性能优化
```bash
# 查看资源使用
docker stats

# 优化MySQL配置
# 编辑 mysql/conf.d/my.cnf
cat > mysql/conf.d/my.cnf << EOF
[mysqld]
innodb_buffer_pool_size = 2G
innodb_log_file_size = 256M
max_connections = 200
query_cache_size = 64M
EOF
```

### 10.3 安全加固
```bash
# 禁用root SSH登录
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# 配置fail2ban
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## 11. 维护和更新

### 11.1 应用更新流程
```bash
# 1. 备份数据
./backup.sh

# 2. 拉取最新代码
git pull origin main

# 3. 重新构建镜像
docker-compose -f docker-compose.prod.yml build

# 4. 重启服务
docker-compose -f docker-compose.prod.yml up -d

# 5. 验证服务
curl -f http://localhost:3000 && echo "Frontend OK"
curl -f http://localhost:8000/api/health && echo "Backend OK"
```

### 11.2 系统维护
```bash
# 清理Docker资源
docker system prune -f

# 更新系统包
sudo apt update && sudo apt upgrade -y

# 重启服务器（如需要）
sudo reboot
```

## 12. 访问应用

部署完成后，可以通过以下方式访问：

- **前端界面**: https://your-domain.com
- **后端API文档**: https://your-domain.com/api/docs
- **Neo4j浏览器**: 通过SSH隧道访问 http://localhost:7474

## 总结

本部署指南涵盖了ChatDB在Vultr服务器上的完整部署流程，包括环境配置、服务部署、安全设置、监控备份等各个方面。请根据实际需求调整配置参数，确保系统安全稳定运行。

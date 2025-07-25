#!/bin/bash

# ChatDB Vultr部署脚本
# 使用方法: ./scripts/deploy.sh

set -e

echo "🚀 开始部署ChatDB到Vultr服务器..."

# 检查必要文件
if [ ! -f ".env" ]; then
    echo "❌ 错误: .env文件不存在，请先复制.env.example并配置"
    exit 1
fi

if [ ! -f "docker-compose.yml" ]; then
    echo "❌ 错误: docker-compose.yml文件不存在"
    exit 1
fi

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: Docker未安装，请先安装Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ 错误: Docker Compose未安装，请先安装Docker Compose"
    exit 1
fi

# 停止现有服务
echo "🛑 停止现有服务..."
docker-compose down || true

# 清理旧镜像（可选）
echo "🧹 清理旧镜像..."
docker system prune -f

# 构建镜像
echo "🔨 构建Docker镜像..."
docker-compose build --no-cache

# 启动服务
echo "🚀 启动服务..."
docker-compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 60

# 检查服务状态
echo "🔍 检查服务状态..."
docker-compose ps

# 初始化数据库
echo "🗄️ 初始化数据库..."
docker-compose exec -T backend python init_db.py

# 验证服务
echo "✅ 验证服务..."
./scripts/health_check.sh

echo "🎉 部署完成！"
echo ""
echo "📱 访问地址:"
echo "   前端界面: http://$(grep SERVER_IP .env | cut -d'=' -f2):3000"
echo "   后端API: http://$(grep SERVER_IP .env | cut -d'=' -f2):8000/docs"
echo ""
echo "💡 提示:"
echo "   - 确保防火墙已开放3000和8000端口"
echo "   - 如需域名访问，可考虑使用Caddy或Vultr负载均衡器"

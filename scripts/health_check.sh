#!/bin/bash

# ChatDB健康检查脚本
# 验证所有服务是否正常运行

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 获取服务器IP
if [ -f ".env" ]; then
    SERVER_IP=$(grep SERVER_IP .env | cut -d'=' -f2)
else
    SERVER_IP="localhost"
fi

echo "🔍 ChatDB健康检查开始..."
echo "📍 服务器IP: $SERVER_IP"

# 检查Docker容器状态
echo -e "\n${YELLOW}1. 检查Docker容器状态${NC}"
docker-compose ps

# 检查前端服务
echo -e "\n${YELLOW}2. 检查前端服务${NC}"
if curl -f -s "http://$SERVER_IP:3000" > /dev/null; then
    echo -e "${GREEN}✅ 前端服务正常${NC}"
else
    echo -e "${RED}❌ 前端服务异常${NC}"
fi

# 检查后端API
echo -e "\n${YELLOW}3. 检查后端API${NC}"
if curl -f -s "http://$SERVER_IP:8000/docs" > /dev/null; then
    echo -e "${GREEN}✅ 后端API正常${NC}"
else
    echo -e "${RED}❌ 后端API异常${NC}"
fi

# 检查MySQL连接
echo -e "\n${YELLOW}4. 检查MySQL数据库${NC}"
if docker-compose exec -T mysql mysql -u root -ppassword -e "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ MySQL连接正常${NC}"
else
    echo -e "${RED}❌ MySQL连接异常${NC}"
fi

# 检查Neo4j连接
echo -e "\n${YELLOW}5. 检查Neo4j图数据库${NC}"
if docker-compose exec -T neo4j cypher-shell -u neo4j -p password "RETURN 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Neo4j连接正常${NC}"
else
    echo -e "${RED}❌ Neo4j连接异常${NC}"
fi

# 检查Milvus连接
echo -e "\n${YELLOW}6. 检查Milvus向量数据库${NC}"
if curl -f -s "http://127.0.0.1:9091/health" > /dev/null; then
    echo -e "${GREEN}✅ Milvus服务正常${NC}"
else
    echo -e "${RED}❌ Milvus服务异常${NC}"
fi

# 检查MinIO存储
echo -e "\n${YELLOW}7. 检查MinIO对象存储${NC}"
if curl -f -s "http://127.0.0.1:9000/minio/health/live" > /dev/null; then
    echo -e "${GREEN}✅ MinIO服务正常${NC}"
else
    echo -e "${RED}❌ MinIO服务异常${NC}"
fi

# 检查etcd服务
echo -e "\n${YELLOW}8. 检查etcd服务${NC}"
if docker-compose exec -T etcd etcdctl endpoint health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ etcd服务正常${NC}"
else
    echo -e "${RED}❌ etcd服务异常${NC}"
fi

# 检查磁盘空间
echo -e "\n${YELLOW}9. 检查磁盘空间${NC}"
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    echo -e "${GREEN}✅ 磁盘空间充足 (${DISK_USAGE}%)${NC}"
else
    echo -e "${RED}⚠️ 磁盘空间不足 (${DISK_USAGE}%)${NC}"
fi

# 检查内存使用
echo -e "\n${YELLOW}10. 检查内存使用${NC}"
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
if [ "$MEMORY_USAGE" -lt 80 ]; then
    echo -e "${GREEN}✅ 内存使用正常 (${MEMORY_USAGE}%)${NC}"
else
    echo -e "${RED}⚠️ 内存使用过高 (${MEMORY_USAGE}%)${NC}"
fi

echo -e "\n${GREEN}🎉 健康检查完成！${NC}"
echo -e "\n📱 访问地址:"
echo -e "   前端: http://$SERVER_IP:3000"
echo -e "   后端API: http://$SERVER_IP:8000/docs"

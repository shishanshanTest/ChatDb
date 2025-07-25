#!/bin/bash

# ChatDB部署验证脚本
# 全面测试前端、后端、数据库、向量库的连通性

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 获取配置
if [ -f ".env" ]; then
    source .env
    SERVER_IP=${SERVER_IP:-localhost}
else
    SERVER_IP="localhost"
fi

echo -e "${BLUE}🧪 ChatDB部署验证测试开始...${NC}"
echo -e "${BLUE}📍 测试服务器: $SERVER_IP${NC}"

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "\n${YELLOW}测试 $TOTAL_TESTS: $test_name${NC}"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ 通过${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}❌ 失败${NC}"
        return 1
    fi
}

# 1. 基础连通性测试
run_test "前端页面响应" "curl -f -s --max-time 10 http://$SERVER_IP:3000 > /dev/null"
run_test "后端API响应" "curl -f -s --max-time 10 http://$SERVER_IP:8000/docs > /dev/null"
run_test "后端健康检查" "curl -f -s --max-time 5 http://$SERVER_IP:8000/api/health > /dev/null || curl -f -s --max-time 5 http://$SERVER_IP:8000/ > /dev/null"

# 2. 数据库连接测试
run_test "MySQL数据库连接" "docker-compose exec -T mysql mysql -u root -ppassword -e 'SELECT 1;' > /dev/null 2>&1"
run_test "Neo4j图数据库连接" "docker-compose exec -T neo4j cypher-shell -u neo4j -p password 'RETURN 1;' > /dev/null 2>&1"

# 3. 向量数据库和存储测试
run_test "Milvus向量数据库" "curl -f -s --max-time 5 http://127.0.0.1:9091/health > /dev/null"
run_test "MinIO对象存储" "curl -f -s --max-time 5 http://127.0.0.1:9000/minio/health/live > /dev/null"
run_test "etcd协调服务" "docker-compose exec -T etcd etcdctl endpoint health > /dev/null 2>&1"

# 4. API功能测试
run_test "获取数据库连接列表" "curl -f -s --max-time 10 http://$SERVER_IP:8000/api/connections > /dev/null"
run_test "API文档可访问" "curl -f -s --max-time 10 http://$SERVER_IP:8000/docs | grep -q 'ChatDB API' || curl -f -s --max-time 10 http://$SERVER_IP:8000/docs > /dev/null"

# 5. 前端功能测试
run_test "前端静态资源" "curl -f -s --max-time 10 http://$SERVER_IP:3000/static/js/ > /dev/null || curl -f -s --max-time 10 http://$SERVER_IP:3000/ | grep -q 'root'"

# 6. 容器状态测试
run_test "所有容器运行中" "[ \$(docker-compose ps -q | wc -l) -eq \$(docker-compose ps -q --filter 'status=running' | wc -l) ]"

# 7. 资源使用测试
run_test "磁盘空间充足" "[ \$(df / | tail -1 | awk '{print \$5}' | sed 's/%//') -lt 90 ]"
run_test "内存使用正常" "[ \$(free | grep Mem | awk '{printf \"%.0f\", \$3/\$2 * 100.0}') -lt 90 ]"

# 8. 网络连通性测试
run_test "容器间网络通信" "docker-compose exec -T backend ping -c 1 mysql > /dev/null 2>&1"
run_test "后端到Neo4j连接" "docker-compose exec -T backend ping -c 1 neo4j > /dev/null 2>&1"
run_test "后端到Milvus连接" "docker-compose exec -T backend ping -c 1 milvus > /dev/null 2>&1"

# 9. 高级功能测试 (可选)
if command -v python3 &> /dev/null; then
    run_test "Python SDK测试Neo4j" "python3 -c \"
from neo4j import GraphDatabase
try:
    driver = GraphDatabase.driver('bolt://$SERVER_IP:7687', auth=('neo4j', 'password'))
    with driver.session() as session:
        result = session.run('RETURN 1 as test')
        print('Neo4j连接成功')
    driver.close()
except Exception as e:
    print(f'Neo4j连接失败: {e}')
    exit(1)
\" > /dev/null 2>&1"
fi

# 10. 日志检查
run_test "无严重错误日志" "! docker-compose logs --tail=50 | grep -i 'error\\|exception\\|failed' | grep -v 'test\\|expected' > /dev/null"

# 测试结果汇总
echo -e "\n${BLUE}📊 测试结果汇总${NC}"
echo -e "总测试数: $TOTAL_TESTS"
echo -e "通过测试: $PASSED_TESTS"
echo -e "失败测试: $((TOTAL_TESTS - PASSED_TESTS))"

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "\n${GREEN}🎉 所有测试通过！部署成功！${NC}"
    echo -e "\n${GREEN}📱 访问地址:${NC}"
    echo -e "   前端: http://$SERVER_IP:3000"
    echo -e "   后端API: http://$SERVER_IP:8000/docs"
    exit 0
else
    echo -e "\n${RED}❌ 部分测试失败，请检查日志${NC}"
    echo -e "\n${YELLOW}🔍 故障排查建议:${NC}"
    echo -e "   1. 检查容器状态: docker-compose ps"
    echo -e "   2. 查看服务日志: docker-compose logs [service_name]"
    echo -e "   3. 检查防火墙: sudo ufw status"
    echo -e "   4. 验证.env配置: cat .env"
    exit 1
fi

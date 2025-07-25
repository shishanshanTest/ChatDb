# ChatDB 部署验证指南

## 🧪 自动化测试

### 快速验证
```bash
# 运行完整的部署验证测试
./scripts/test_deployment.sh

# 运行基础健康检查
./scripts/health_check.sh
```

## 🌐 浏览器手动测试

### 1. 前端功能测试

访问: `http://your_server_ip:3000`

**测试检查点:**
- [ ] 页面正常加载，显示"智能数据分析系统"标题
- [ ] 左侧导航菜单显示：智能查询、智能问答、数据建模、图数据可视化、连接管理、数据映射
- [ ] 页面无JavaScript错误（F12开发者工具Console）
- [ ] 网络请求正常（F12开发者工具Network）

**功能测试:**
1. **连接管理页面** (`/connections`)
   - [ ] 可以点击"添加连接"按钮
   - [ ] 表单字段正常显示
   - [ ] 可以输入数据库连接信息

2. **智能查询页面** (`/text2sql`)
   - [ ] 输入框显示"请输入您的问题"
   - [ ] 可以选择数据库连接
   - [ ] 界面响应正常

3. **数据建模页面** (`/schema`)
   - [ ] 画布区域正常显示
   - [ ] 左侧面板可以展开

### 2. 后端API测试

访问: `http://your_server_ip:8000/docs`

**测试检查点:**
- [ ] Swagger UI正常加载
- [ ] API文档显示完整
- [ ] 可以展开API端点
- [ ] "Try it out"功能可用

**API端点测试:**
1. **GET /api/connections** - 获取数据库连接列表
2. **GET /api/health** - 健康检查端点
3. **GET /api/schema/{connection_id}/discover** - 模式发现

## 🔧 命令行测试

### cURL测试命令

```bash
# 设置服务器IP
SERVER_IP="your_vultr_server_ip"

# 1. 测试前端
curl -I http://$SERVER_IP:3000
# 期望: HTTP/1.1 200 OK

# 2. 测试后端API文档
curl -I http://$SERVER_IP:8000/docs
# 期望: HTTP/1.1 200 OK

# 3. 测试API端点
curl -X GET http://$SERVER_IP:8000/api/connections
# 期望: JSON响应 []

# 4. 测试健康检查
curl http://$SERVER_IP:8000/api/health
# 期望: {"status": "healthy"}
```

### Docker测试命令

```bash
# 1. 检查所有容器状态
docker-compose ps
# 期望: 所有服务显示"Up"状态

# 2. 检查容器日志
docker-compose logs frontend
docker-compose logs backend
docker-compose logs mysql
docker-compose logs neo4j
docker-compose logs milvus

# 3. 测试容器间网络
docker-compose exec backend ping mysql
docker-compose exec backend ping neo4j
docker-compose exec backend ping milvus
```

## 🗄️ 数据库连接测试

### MySQL测试
```bash
# 连接MySQL
docker-compose exec mysql mysql -u root -ppassword

# 测试SQL
mysql> SHOW DATABASES;
mysql> USE chatdb;
mysql> SHOW TABLES;
```

### Neo4j测试
```bash
# 连接Neo4j
docker-compose exec neo4j cypher-shell -u neo4j -p password

# 测试Cypher
neo4j> MATCH (n) RETURN count(n);
neo4j> CALL db.labels();
```

### Milvus测试
```bash
# 检查Milvus健康状态
curl http://127.0.0.1:9091/health

# 检查Milvus Web UI
curl -I http://127.0.0.1:9091
```

## 🐍 Python SDK测试

### Neo4j Python测试
```python
from neo4j import GraphDatabase

# 连接测试
driver = GraphDatabase.driver(
    "bolt://your_server_ip:7687", 
    auth=("neo4j", "password")
)

with driver.session() as session:
    result = session.run("RETURN 1 as test")
    print(result.single()["test"])

driver.close()
```

### Milvus Python测试
```python
from pymilvus import connections, utility

# 连接测试
connections.connect(
    alias="default",
    host="your_server_ip",
    port="19530"
)

# 检查连接
print(utility.get_server_version())
```

## 🚨 故障排查

### 常见问题及解决方案

1. **前端无法访问**
   ```bash
   # 检查容器状态
   docker-compose ps frontend

   # 检查端口占用
   netstat -tlnp | grep :3000

   # 检查防火墙
   sudo ufw status

   # 确保端口已开放
   sudo ufw allow 3000
   sudo ufw allow 8000
   ```

2. **后端API无响应**
   ```bash
   # 检查后端日志
   docker-compose logs backend
   
   # 检查数据库连接
   docker-compose exec backend python -c "
   from app.db.session import SessionLocal
   db = SessionLocal()
   print('Database connected!')
   db.close()
   "
   ```

3. **数据库连接失败**
   ```bash
   # 重启数据库服务
   docker-compose restart mysql neo4j
   
   # 检查数据卷
   docker volume ls | grep chatdb
   ```

4. **Milvus服务异常**
   ```bash
   # 检查依赖服务
   docker-compose logs etcd minio
   
   # 重启Milvus相关服务
   docker-compose restart etcd minio milvus
   ```

## ✅ 验收标准

部署成功的标准：
- [ ] 所有Docker容器正常运行
- [ ] 前端页面可以正常访问和操作
- [ ] 后端API文档可以访问
- [ ] 数据库连接正常
- [ ] 可以创建和测试数据库连接
- [ ] 智能查询功能可以使用
- [ ] 系统资源使用正常（CPU < 80%, 内存 < 80%, 磁盘 < 80%）
- [ ] 无严重错误日志

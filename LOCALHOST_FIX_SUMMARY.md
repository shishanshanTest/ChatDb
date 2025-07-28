# 前端硬编码localhost修复总结

## 🎯 修复目标
将前端代码中所有硬编码的 `http://localhost:8000` 替换为 `http://backend:8000`，以支持Docker容器间通信。

## 📋 修复的文件列表

### 1. frontend/src/services/chatHistoryService.ts
**修改内容**：
```typescript
// 修改前
const API_BASE_URL = 'http://localhost:8000/api';

// 修改后  
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://backend:8000/api';
```

### 2. frontend/src/services/api.ts
**修改内容**：
```typescript
// 修改前
const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api';

// 修改后
const API_URL = process.env.REACT_APP_API_URL || 'http://backend:8000/api';
```

### 3. frontend/src/services/hybridQA.ts
**修改内容**：
```typescript
// 修改前
const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api';

// 修改后
const API_URL = process.env.REACT_APP_API_URL || 'http://backend:8000/api';
```

### 4. frontend/src/services/websocket-manager.ts
**修改内容**：
```typescript
// 修改前
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api';

// 修改后
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://backend:8000/api';
```

### 5. frontend/src/pages/text2sql/services/XStreamService.ts
**修改内容**：
```typescript
// 修改前
constructor(baseUrl: string = 'http://localhost:8000/api/text2sql-sse/stream') {

// 修改后
constructor(baseUrl: string = 'http://backend:8000/api/text2sql-sse/stream') {

// 以及
// 修改前
const feedbackUrl = `http://localhost:8000/api/text2sql-sse/feedback/${sessionId}`;

// 修改后
const feedbackUrl = `http://backend:8000/api/text2sql-sse/feedback/${sessionId}`;
```

### 6. frontend/src/pages/text2sql/api.ts
**修改内容**：
```typescript
// 修改前
const api = axios.create({
  baseURL: 'http://localhost:8000/api',
});

// 修改后
const api = axios.create({
  baseURL: process.env.REACT_APP_API_URL || 'http://backend:8000/api',
});

// 以及
// 修改前
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api';

// 修改后
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://backend:8000/api';
```

### 7. frontend/src/pages/text2sql/api-sse.ts
**修改内容**：
```typescript
// 修改前
const api = axios.create({
  baseURL: 'http://localhost:8000/api',
});

// 修改后
const api = axios.create({
  baseURL: process.env.REACT_APP_API_URL || 'http://backend:8000/api',
});

// 以及
// 修改前
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api';

// 修改后
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://backend:8000/api';
```

### 8. frontend/src/pages/text2sql/sse-api.ts
**修改内容**：
```typescript
// 修改前
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api';

// 修改后
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://backend:8000/api';
```

## 🔧 修复原理

### 问题原因
1. **Docker容器网络隔离**：前端容器内的 `localhost` 指向容器本身，无法访问后端容器
2. **硬编码URL**：部分文件直接写死了 `localhost:8000`，不使用环境变量

### 解决方案
1. **使用Docker服务名**：`backend:8000` 是Docker Compose中后端服务的内部网络地址
2. **保持环境变量支持**：优先使用 `REACT_APP_API_URL` 环境变量，fallback到 `backend:8000`
3. **统一配置**：所有API配置都使用相同的模式

## 📋 部署步骤

### 1. 提交代码到仓库
```bash
git add frontend/src/
git commit -m "fix: replace hardcoded localhost:8000 with backend:8000 for Docker internal network"
git push origin main
```

### 2. 在Vultr服务器上更新
```bash
# 进入项目目录
cd /opt/chatdb

# 拉取最新代码
git pull origin main

# 重新构建前端容器
docker-compose build --no-cache frontend

# 重启前端容器
docker-compose restart frontend
```

### 3. 验证修复
```bash
# 检查前端日志
docker-compose logs frontend

# 检查浏览器console，应该看到API请求指向backend:8000而不是localhost:8000
```

## ✅ 预期效果

修复后，前端应用将：
1. **正确连接后端**：通过Docker内部网络访问后端服务
2. **API请求成功**：数据库连接、聊天历史等功能正常工作
3. **无localhost错误**：浏览器console不再显示localhost连接错误

## 🎯 优势

1. **使用Docker内部网络**：最稳定的容器间通信方式
2. **保持环境变量支持**：仍然支持通过环境变量自定义API地址
3. **向后兼容**：不影响现有的环境变量配置
4. **彻底解决**：修复了所有硬编码的localhost引用

这个修复方案彻底解决了前端无法连接后端的问题，无需修改Docker网络配置或其他复杂设置。

BFF 是 **Backend for Frontend** 的缩写，意思是**为前端服务的后端**。

像一个典型场景：你的前端应用（比如手机 App）需要展示一个用户主页，包含用户基本信息、最近订单、推荐商品。后端有 3 个独立的微服务：

- 用户服务 `/api/users/{id}`
- 订单服务 `/api/orders?userId={id}`
- 推荐服务 `/api/recommendations?userId={id}`

**没有 BFF 时**，前端要发 3 个请求，还要处理：

- 不同服务的认证方式
- 数据聚合、裁剪、格式转换
- 网络环境差时的性能问题
- 移动端带宽和电量消耗

**有了 BFF 后**，前端只需调用：

```
GET /mobile-api/user-homepage/{id}
```

BFF 层会帮你聚合三个服务的数据，返回前端恰好需要的格式。



BFF 的本质是**关注点分离**：

- **传统后端**：提供通用、完整的领域模型
- **BFF**：提供**视图导向**（view-specific）的定制化接口，为特定前端体验优化

它不是“另一个后端服务”，而是**前端团队的“后端代理”**，通常由前端开发者负责编写。



关键特征：

1. **按用户体验切分**：Web、iOS、Android 可能有各自的 BFF
2. **轻量聚合**：只做路由、聚合、裁剪，不包含复杂业务逻辑
3. **前端驱动**：接口设计由前端需求主导，迭代快速
4. **薄层**：保持简单，避免业务逻辑泄露

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│ iOS App     │      │ Web Admin   │      │ Mini Program│
└──────┬──────┘      └──────┬──────┘      └──────┬──────┘
       │                    │                    │
       │                    │                    │
┌──────▼──────┐      ┌──────▼──────┐      ┌──────▼──────┐
│ iOS BFF     │      │ Admin BFF   │      │ MP BFF      │
│ (Node.js)   │      │ (Node.js)   │      │ (Node.js)   │
└──────┬──────┘      └──────┬──────┘      └──────┬──────┘
       │                    │                    │
       └──────────┬─────────┴──────────┬─────────┘
                  │                    │
            ┌─────▼────────────────────▼─────┐
            │  后端微服务层（Domain Services）│
            │  - User Service                │
            │  - Order Service               │
            │  - Permission Service          │
            └────────────────────────────────┘
```



权衡与陷阱：

- **成本**：增加了一层服务，有运维复杂度
- **重复**：不同 BFF 可能出现重复代码
- **边界模糊**：容易把业务逻辑写进 BFF，导致“胖 BFF”

**建议**：先让后端服务足够“瘦”和“内聚”，再考虑 BFF。不要为了“时髦”而引入。



举例：

```js
// BFF 层（Node.js）
app.get('/mobile-api/user-homepage/:id', async (req, res) => {
  // 并行调用多个服务
  const [user, orders, recs] = await Promise.all([
    fetch(`/api/users/${req.params.id}`).then(r => r.json()),
    fetch(`/api/orders?userId=${req.params.id}&limit=5`).then(r => r.json()),
    fetch(`/api/recommendations?userId=${req.params.id}`).then(r => r.json())
  ])
  
  // 裁剪成移动端恰好需要的数据
  res.json({
    userName: user.name,
    avatar: user.avatar.small, // 只返回小图
    recentOrders: orders.map(o => ({
      id: o.id,
      title: o.productName,
      price: o.price
    })),
    recommendations: recs.slice(0, 3) // 只取前 3 个
  })
})
```

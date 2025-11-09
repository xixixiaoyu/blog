轮询是一种在客户端和服务器之间进行通信的技术，主要用于从服务器获取实时更新数据。根据轮询的机制，可以分为短轮询和长轮询。

## 短轮询
短轮询是一种简单的轮询方式，客户端以固定的时间间隔向服务器发送请求，不论服务器是否有数据更新。

```javascript
import axios from 'axios';

function shortPolling() {
  setInterval(() => {
    axios.get('/api/data')
      .then(response => {
        console.log('短轮询数据:', response.data);
        // 处理数据
      })
      .catch(error => {
        console.error('短轮询错误:', error);
      });
  }, 5000); // 每5秒请求一次
}

shortPolling();
```

适用场景：适合实时性要求不高、需要控制服务器负载的场景。





## 长轮询
长轮询是一种更加高效的轮询方式。客户端发送请求后，服务器会保持请求开放，直到有新数据可发送或达到超时时间。

```javascript
import axios from 'axios';

function longPolling() {
  function poll() {
    axios.get('/api/data', {
      timeout: 60000 // 设置长时间的超时时间
    })
      .then(response => {
        console.log('长轮询数据:', response.data);
        // 处理数据
        poll(); // 数据处理完毕后，再次发起长轮询请求
      })
      .catch(error => {
        if (axios.isCancel(error)) {
          console.log('长轮询被取消:', error.message);
        } else {
          console.error('长轮询错误:', error);
        }
        setTimeout(poll, 5000); // 发生错误后，等待5秒再次发起请求
      });
  }

  poll();
}

longPolling();
```

适用场景：适合需要较高实时性、减少请求次数的场景。

短轮询和长轮询相比，都不如 WebSocket 和 Server-Sent Events（SSE）在实时性和效率上表现好。



## WebSocket 和 SSE 通信过程
#### WebSocket
+ 客户端发起握手：客户端向服务器发送一个特殊的 HTTP 请求，请求中包含 Upgrade: websocket 和 Connection: Upgrade 头部字段，表明客户端希望将通信协议从 HTTP 升级到 WebSocket。
+ 服务器响应握手：如果服务器支持 WebSocket，则会返回一个 HTTP 响应，状态码为 101，同时携带相应的头部字段 Upgrade: websocket 和 Connection: Upgrade，确认协议切换。
+ 数据传输：握手成功后，客户端和服务器可以直接交换文本和二进制数据，不需要像传统的 HTTP 请求那样每次交互都需要发起一个新的请求。
+ 关闭连接：任何一方可以通过发送一个关闭帧来发起关闭连接的握手，该帧包含关闭的原因和状态码。





#### SSE
SSE 是一种轻量级的协议，允许服务器向客户端推送实时数据。适用于如下场景：

+ 私信通知
+ 股票行情更新
+ 新闻订阅



而基于 HTTP 协议的 Server Send Event 通信过程：

1. **客户端请求**：通过普通的HTTP GET请求，并在头部包含 Accept: text/event-stream。
2. **服务器响应**：保持连接打开，设置响应 Content-Type: text/event-stream，开始发送数据，可以多次发送。
3. **发送消息**：服务器按照 SSE 的格式发送消息，每条消息通常包含一个事件类型（event）、数据（data）和一个可选的 id。消息以两个换行符 \n\n 结尾。例如

```plain
data: 第一条消息内容\n\n
```

或者，如果一条消息包含多行数据，它会这样发送：

```plain
data: first line\n
data: second line\n\n
```

如果指定了事件类型和 id，它们将作为消息的一部分被发送：

```plain
id: 1
event: myMessage
data: 第二条消息内容\n\n
```

4. **客户端处理**：在 JS 中，通过创建一个 EventSource 对象并监听它的 onmessage 事件。如果服务器指定了事件类型，例如上面指定了 myMessage，客户端需要监听 myMessage 事件类型以收到数据。
5. **保持连接**：如果连接断开，客户端会尝试重新连接。如果服务器提供了 id，客户端会在重连时发送 Last-Event-ID 头部，以便服务器从正确的数据点继续发送。
6. **关闭连接**：客户端可以调用 EventSource 对象的 close() 方法关闭连接。服务器也可以通过发送特定消息指示关闭。

CI/CD 平台的实时日志打印，ChatGPT 的分段加载回答，通常基于 SSE 实现。

SSE 通常用于传输文本数据，不推荐用于传输大量二进制数据。



## Nest 实现 SSE 接口
我们实现一下，创建 nest 项目：

```bash
npx nest new sse-project
```

运行：

```bash
npm run start:dev
```

在 AppController 添加一个 stream 接口：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1706957776302-c82ceab7-ecda-43f5-a51f-ef0e56c2f70f.png)

使用 `@Sse()` 装饰器来标记为 SSE 端点。

返回的是一个 Observable 对象，然后内部用 observer.next 返回消息。

sse1 我们先返回了 'hello'，三秒后返回了 'world'。



我们支持下跨域：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1706957258939-87c8e508-4330-4f0f-a2fd-e73ef44506df.png)



## React 接收 SSE 接口数据
写一个前端页面，创建 react 项目：

```javascript
npx create-react-app --template=typescript sse-project-frontend
```

在 App.tsx 里写如下代码：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1706958281524-9804b928-785c-4f2f-905b-779c1c0aa055.png)

通过 new EventSource 这个原生 API，监听上面的  onmessage 回调函数，获取 sse 接口的响应。







将渲染 App 外层的严格模式注释，它会导致多余的渲染。

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693321854316-68ecbfc0-2674-4a3d-8fb9-acb70ef3558d.png)

执行 npm run start。



因为 3000 端口被 nest 应用占用了，react 应用跑在 3001 端口。

点击 event1 按钮：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1706958332760-d7af04e2-6409-4ba8-a0e1-b10d7bb30519.png)

控制台先打印 'hello'，三秒后打印 'world'，我们可以取里面的 data 属性拿到最终数据：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1706958389028-ae0afde1-ad92-41d6-9b25-dae31be152c1.png)



点击 even2 按钮：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1706958485756-29195a0c-23f0-4ba7-97cf-f4015f303063.png)

控制台不断打印：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1706958516008-d79ecf9e-a04a-478c-af6f-56e849446a23.png)

表明我们不断收到服务端推送的数据。



响应的 Content-Type 是 text/event-stream：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1706958596680-d9d96ab7-bf39-4fc2-a5ac-54baecd98b17.png)

然后在 EventStream 可以看到每次收到的消息：  
![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1706958609967-756f2155-fee0-461a-b770-95fa71c0d5e2.png)



## SSE 日志实时推送
`tail -f` 命令可以实时看到文件的最新内容：

我们可以通过 child_process 模块的 exec 来执行这个命令，监听 log 文件改动，返回给客户端改动内容：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1706960582471-d23b3542-b24f-4a21-b62b-5b3aadfb7b9a.png)

`./log` 指的是当前工作目录下名为 `log` 的文件。在这里，`.` 表示当前工作目录。

可以输入 `node` 然后再输入 `process.cwd()` 来查看当前的工作目录。

前端连接这个新接口：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1706960706384-7f1449b6-ef06-4a09-8c47-73d6d2d8db6e.png)

输入 111 保存，再输入 222 保存：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1706960834211-470fe49a-2a01-47b3-a542-f9ae2ba7a4ad.png)

控制台打印两条信息：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1706960781896-cdaeae42-34c8-4cea-b25d-a4805849c92b.png)

浏览器收到了实时的日志，可以对 data 属性值进行 `JSON.parse()`。

很多构建日志都是通过 SSE 的方式实时推送的。


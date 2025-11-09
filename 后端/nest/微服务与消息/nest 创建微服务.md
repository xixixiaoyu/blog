## <font style="background-color:rgba(255, 255, 255, 0);">单体架构的局限性</font>
<font style="background-color:rgba(255, 255, 255, 0);">单体架构将所有业务逻辑都在一个服务中。</font>

<font style="background-color:rgba(255, 255, 255, 0);">这样当项目越来越大、模块越来越多的时候，代码会越来越难维护：</font>

![画板](https://cdn.nlark.com/yuque/0/2024/jpeg/21596389/1711257113232-70c4ea73-0a75-4e67-96bb-f65b237a5014.jpeg)



## <font style="background-color:rgba(255, 255, 255, 0);">微服务架构的优势</font>
<font style="background-color:rgba(255, 255, 255, 0);">为了单体架构的问题，微服务架构应运而生。</font>

<font style="background-color:rgba(255, 255, 255, 0);">我们可以把业务模块拆成单独的服务，每个服务负责特定的业务模块：</font>

![画板](https://cdn.nlark.com/yuque/0/2024/jpeg/21596389/1711257211740-9f50b4a2-b18f-413d-a6d8-d50b9eddb030.jpeg)

<font style="background-color:rgba(255, 255, 255, 0);">微服务之间直接使用 TCP 通信，减少开销。</font>

<font style="background-color:rgba(255, 255, 255, 0);">不使用 HTTP 进行通信，因为 HTTP 请求头携带大量信息，增加了通信开销。</font>



## <font style="background-color:rgba(255, 255, 255, 0);">Nest 微服务实现</font>
<font style="background-color:rgba(255, 255, 255, 0);">创建两个 nest 项目</font>

```typescript
// 作为 http 服务向外提供接口
nest new microservice-test-main
// 微服务，提供 tcp 的微服务通信端口
nest new microservice-test-user
```

<font style="background-color:rgba(255, 255, 255, 0);"></font>

### <font style="background-color:rgba(255, 255, 255, 0);">微服务应用提供接口</font>
<font style="background-color:rgba(255, 255, 255, 0);">进入 microservice-test-user，安装微服务的包：</font>

```bash
npm install @nestjs/microservices
```

<font style="background-color:rgba(255, 255, 255, 0);">mian.ts 修改如下：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693240132521-889573b2-1851-4d76-b1e7-3dbe1955c1a6.png)

<font style="background-color:rgba(255, 255, 255, 0);">使用 TCP 通信：通过 NestFactory.createMicroservice 创建微服务，监听 8888 端口。</font>

<font style="background-color:rgba(255, 255, 255, 0);"></font>

<font style="background-color:rgba(255, 255, 255, 0);">使用 </font>`<font style="background-color:rgba(255, 255, 255, 0);">@MessagePattern</font>`<font style="background-color:rgba(255, 255, 255, 0);"> 定义一个消息处理模式：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693240196817-a053ec91-0606-4baf-b205-723397ea0cd2.png)

<font style="background-color:rgba(255, 255, 255, 0);">这样，我们就创建了一个微服务：</font>

![画板](https://cdn.nlark.com/yuque/0/2024/jpeg/21596389/1710001370256-2f112cff-f735-419e-995e-8439712f210c.jpeg)

<font style="background-color:rgba(255, 255, 255, 0);">如果并不需要返回消息的话，可以用 @EventPattern 声明：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693241045256-63ae4202-4eef-4b40-965a-63999e875b4a.png)

<font style="background-color:rgba(255, 255, 255, 0);"></font>

### <font style="background-color:rgba(255, 255, 255, 0);">主服务使用微服务</font>
<font style="background-color:rgba(255, 255, 255, 0);">进入 microservice-test-main，安装微服务相关的包：</font>

```bash
npm install @nestjs/microservices
```

<font style="background-color:rgba(255, 255, 255, 0);"></font>

<font style="background-color:rgba(255, 255, 255, 0);">在 AppModule </font><font style="background-color:rgba(255, 255, 255, 0);">通过 ClientsModule 模块连接到微服务</font><font style="background-color:rgba(255, 255, 255, 0);">：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693240341180-23aedb6c-5bcc-4644-bc65-26acd8ebf474.png)

<font style="background-color:rgba(255, 255, 255, 0);">这里的 register 参数是一个数组，当有多个微服务的时候，依次写在这里。</font>

<font style="background-color:rgba(255, 255, 255, 0);"></font>

<font style="background-color:rgba(255, 255, 255, 0);">然后就可以使用 </font><font style="background-color:rgba(255, 255, 255, 0);">ClientProxy </font><font style="background-color:rgba(255, 255, 255, 0);">对象通过 </font><font style="background-color:rgba(255, 255, 255, 0);">send </font><font style="background-color:rgba(255, 255, 255, 0);">方法调用微服务的 </font><font style="background-color:rgba(255, 255, 255, 0);">sum </font><font style="background-color:rgba(255, 255, 255, 0);">方法。</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693240701492-8d7a25a7-dc93-4fb3-8ac6-31460a2ef783.png)

<font style="background-color:rgba(255, 255, 255, 0);"></font>

<font style="background-color:rgba(255, 255, 255, 0);">把两个服务都跑起来：</font>

```typescript
npm run start:dev
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693240783441-2076c94a-f938-4a49-b9b5-3411ff396485.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693240791301-fcfed319-cbf5-4246-820c-ef63f9f86d8f.png)

<font style="background-color:rgba(255, 255, 255, 0);"></font>

<font style="background-color:rgba(255, 255, 255, 0);">然后浏览器访问下 </font>[<font style="background-color:rgba(255, 255, 255, 0);">http://localhost:3000/sum?num=3,5,6</font>](https://link.juejin.cn/?target=http%3A%2F%2Flocalhost%3A3000%2Fsum%3Fnum%3D3%2C5%2C6%25EF%25BC%259A)<font style="background-color:rgba(255, 255, 255, 0);"></font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693240888521-7a27cc72-d015-4635-94fb-6e3edb62946e.png)

<font style="background-color:rgba(255, 255, 255, 0);">返回了 14，是 3 + 5 + 6 的结果。</font>

<font style="background-color:rgba(255, 255, 255, 0);"></font>

<font style="background-color:rgba(255, 255, 255, 0);">浏览器把 3、5、6 的参数传递给 http 服务，然后它给微服务发送消息，把参数带过去，微服务计算后返回了 14 给 http 服务，它再返回给浏览器：</font>

![画板](https://cdn.nlark.com/yuque/0/2024/jpeg/21596389/1710001069803-8e0199cc-dbf0-452b-9c5d-128033850cfc.jpeg)

<font style="background-color:rgba(255, 255, 255, 0);"></font>

<font style="background-color:rgba(255, 255, 255, 0);">之前微服务 @EventPattern 声明的方法，这边要用 emit 方法调用：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693241076710-1541c14e-1400-4ae4-b78e-e4fdab8b7ed0.png)

<font style="background-color:rgba(255, 255, 255, 0);">测试下：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693241115541-94a9cc31-1414-4ef0-935e-5a11cf3dbc58.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693241139285-4f6e975a-9c18-4dd6-b604-7b7e30cd6e1e.png)

<font style="background-color:rgba(255, 255, 255, 0);">可以看到，微服务收到了这边发送的消息，并打印了日志。</font>

<font style="background-color:rgba(255, 255, 255, 0);"></font>

## <font style="background-color:rgba(255, 255, 255, 0);">wireshark 抓包</font>
<font style="background-color:rgba(255, 255, 255, 0);">想抓微服务 tcp 层的包需要用到 wireshark。</font>

<font style="background-color:rgba(255, 255, 255, 0);">在 </font>[<font style="background-color:rgba(255, 255, 255, 0);">wireshark 官网</font>](https://link.juejin.cn/?target=https%3A%2F%2Fwww.wireshark.org%2F)<font style="background-color:rgba(255, 255, 255, 0);">下载安装包。</font>

<font style="background-color:rgba(255, 255, 255, 0);">选择 loopback 这个网卡，本地回环地址，可以抓到 localhost 的包：  
</font>![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693241654098-9ea445d7-ef38-4934-8c06-455e499c295b.png)

<font style="background-color:rgba(255, 255, 255, 0);">输入过滤器 port 8888，也就是过滤 8888 端口的数据包。</font>

<font style="background-color:rgba(255, 255, 255, 0);">然后回车就会进入抓包界面：</font>

<font style="background-color:rgba(255, 255, 255, 0);">这时候再访问下 </font>[<font style="background-color:rgba(255, 255, 255, 0);">http://localhost:3000/sum?num=3,5,7</font>](http://localhost:3000/sum?num=3,5,7)

<font style="background-color:rgba(255, 255, 255, 0);">可以看到抓到了几个 tcp 的包：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693241775959-019bb14c-b9b2-47fa-9d4a-d6fd881a94d3.png)

<font style="background-color:rgba(255, 255, 255, 0);">点开这几个 PSH 的包看一下：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693241882217-9aa7b469-dab9-4518-850b-4d31731a48b8.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693241900998-8aa10313-a063-4b81-882b-94361bc39a9a.png)![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693241915102-2cd5986f-fc10-4b41-8bb0-3e00bc862d3b.png)

<font style="background-color:rgba(255, 255, 255, 0);">内容如下：</font>

```typescript
{"pattern": "log", "data": "求和"}
{"pattern": "sum", data: [3, 5, 7], "id": "3b4a92305a76109bf0e79"}
{"response": 15, "isDisposed": true, "id": "3b4a92305a76109bf0e79"}
```

<font style="background-color:rgba(255, 255, 255, 0);">前两个是主服务发送给微服务的，后面那个是微服务返回的。</font>

<font style="background-color:rgba(255, 255, 255, 0);">从抓包数据我们看出：</font>

+ <font style="background-color:rgba(255, 255, 255, 0);">微服务之间的 tcp 通信的消息格式是 json</font>
+ <font style="background-color:rgba(255, 255, 255, 0);">如果是 message 的方式，需要两边各发送一个 tcp 包，也就是一问一答的方式</font>
+ <font style="background-color:rgba(255, 255, 255, 0);">如果是 event 的方式，只需要客户端发送一个 tcp 的包</font>


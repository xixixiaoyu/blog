nest 很多功能基于装饰器实现，我们有必要好好了解下有哪些装饰器：

创建 nest 项目：

```bash
nest new all-decorator -p npm
```



## @Module({})
这是一个类装饰器，用于定义一个模块。

模块是 Nest.js 中组织代码的单元，可以包含控制器、提供者等：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1686408310818-bf8ba5fd-ff6b-4228-b39b-d135143fa318.png)



## @Controller() 和 @Injectable()
这两个装饰器也是类装饰器，前者控制器负责处理传入的请求和返回响应，后者定义一个服务提供者，可以被注入到控制器或其他服务中。

通过 `@Controller`、`@Injectable` 分别声明 controller 和 provider：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1686408371516-1c8c97b5-6a8d-4958-a554-5547392feef4.png)



## @Optional、@Inject
可选依赖注入可以用 `@Optional` 声明，这样在没有对应 provider 时也不会抛出错误。

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1686408762999-a056f8a2-43d9-4e5a-8691-ffe8cd419d3b.png)

注入依赖也可以用 @Inject 装饰器。



## @Catch
filter 是处理抛出的未捕获异常，通过 `@Catch` 来指定处理的异常：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1686409319833-455f489a-b50d-4891-89ec-1a8643a7eeb3.png)



## @UseXxx、@Query、@Param
使用 @UseFilters 应用 filter 到 handler 上：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1686409349507-702b3079-987e-422a-80a8-47fc916958a4.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1686409381750-0a9c6170-2aa1-4847-b543-5e6d50ca0422.png)

除了 filter 之外，interceptor、guard、pipe 也是这样用：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1686409705702-e7b7d88e-862c-4b35-959c-96e47812025f.png)



## @Body
如果是 post、put、patch 请求，可以通过 @Body 取到 body 部分：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1686447899628-8c81c1ec-c142-424d-b6d5-e56eff03ff53.png)

我们一般用 dto 定义的 class 来接收验证请求体里的参数。



## @Put、@Delete、@Patch、@Options、@Head
@Put、@Delete、@Patch、@Options、@Head 装饰器分别接受 put、delete、patch、options、head 请求：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1686448159943-3c00c47d-cb03-4ce7-b74d-8650be342db4.png)



## @SetMetadata
通过 `@SetMetadata` 指定 metadata，作用于 handler 或 class

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1686448932281-49c8e61a-4a35-4225-ab5f-22833ad7ba8c.png)

然后在 guard 或者 interceptor 里取出来：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1686448981067-bdf380c3-d6e6-456a-a6d1-fa596832c1dd.png)



## @Headers
可以通过 @Headers 装饰器取某个请求头或者全部请求头：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1686449246067-111c59af-8afd-49bd-a5e6-45bf8a7e2b82.png)



## @Ip
通过 @Ip 拿到请求的 ip，通过 @Session 拿到 session 对象：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1686449541437-84cbadea-f930-4246-b8e5-c9c07e4c12c7.png)



## @HostParam
@HostParam 用于取域名部分的参数。

下面 host 需要满足 xxx.0.0.1 到这个 controller，host 里的参数就可以通过 @HostParam 取出来：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709090008374-82ea7d36-02ac-47be-a770-7230da51448c.png)



## @Req、@Request、@Res、@Response
前面取的这些都是 request 里的属性，当然也可以直接注入 request 对象：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1686453804267-f4a35225-155c-4a4c-b98e-b5fd4181cec0.png)

@Req 或者 @Request 装饰器，这俩是同一个东西。



使用 @Res 或 @Response 注入 response 对象，但是注入 response 对象之后，服务器会一直没有响应。

因为这时候 Nest 就不会把 handler 返回值作为响应内容了。我们可以自己返回响应：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1686453975966-a243a1a7-ec27-49af-8e8e-a4a5271034dd.png)

Nest 这么设计是为了避免相互冲突。

如果你不会自己返回响应，可以设置 passthrough 为 true 告诉 Nest：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1686454086356-faa726ef-6524-47da-b9a8-47e25129468d.png)



## @Next
在基于 Express 的适配器下，`@Next()` 可获取 `next` 函数用于中间件链的传递。通常不在控制器中用于转发到另一处理器。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709089130298-cb4e97de-f7ac-4041-82af-a6a8c68f8a61.png)



## @HttpCode
handler 默认返回的是 200 的状态码，你可以通过 @HttpCode 修改它：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709088572795-be3329a0-6eef-4518-b6e4-c10e96ec1698.png)



## @Header
当然，你也可以修改 response header，通过 @Header 装饰器：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709088658283-5fbd8112-c2ab-41a3-b954-4e0e47eae6be.png)







<font style="background-color:rgba(255, 255, 255, 0);"></font>

## **对象存储服务（OSS）介绍**
文件上传是常见的网络需求，通常我们不会将文件直接上传到应用服务器，因为单台服务器的存储空间有限，不易扩展。

为此，我们通常使用对象存储服务（Object Storage Service，简称OSS）来完成文件的上传和下载。例如，阿里云提供的 OSS 服务就是这样一个平台。

OSS 存储和检索非结构化数据和元数据对象（如文档、图片、视频等）。



## 本地存储和 OSS 存储结构对比
本地文件存储：采用目录和文件的组织方式。

OSS 存储结构：

+ OSS 中的对象是存储的基本单元，每个对象包含数据、元数据和唯一标识符。
+ 桶（Bucket）是用于组织对象的容器，每个桶内可以存储无数个对象，并且可以通过 RESTful API 接口进行操作。
+ 值得注意的是，虽然阿里云 OSS 的控制台显示对象存储没有目录层级结构，但它实际上是通过元数据部分模拟实现了目录层级，使得用户可以使用“标签”来检索文件。



## 阿里云的其他存储服务
除了对象存储OSS，阿里云还提供文件存储和块存储服务。

文件存储具有目录层次结构，可以上传和下载文件，但存储容量有限。

块存储则是将整块磁盘提供给你，需要自行格式化，存储容量同样有限。

对象存储OSS则是分布式实现的 key-value 存储，存储容量几乎是无限的。

绝大多数情况下，我们都是用 OSS 对象存储。



## OSS 服务购买
我们买个[阿里云的 OSS 服务](https://link.juejin.cn/?target=https%3A%2F%2Fwww.aliyun.com%2Fproduct%2Foss)：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713062461334-721cf042-75b8-49ae-85f8-0c6c1e2adf3c.png)

我买了 40G 的 OSS 国内通用资源包，花了 5 块钱。



然后我们创建个 Bucket（桶）：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713062804198-4865278d-f440-4c6a-8f14-e5c9836431e7.png)

在北京创建了一个 Bucket，文件就会存储在那里的服务器上。

可以设置为公共读，也可以设置为私有，需要身份验证才能访问。

如果文件仅存储在北京的服务器上，那么在其他地区访问是否会受到速度的影响？

这就是 CDN（内容分发网络）的用武之地。通过 CDN，用户访问特定域名时，会被引导至最近的缓存服务器，从而加速文件的访问速度。



## 控制台上传文件
创建 Bucket 之后，我们就可以上传文件了：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713063147392-f7e8c2d2-a5d2-4074-b217-21dd505a10b4.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713063186426-ae845da0-ef93-405d-b2ab-ced5e206068a.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713063212410-b943d441-9240-4b0c-9526-b684616a1879.png)



上传完之后在文件列表就可以看到这个文件了：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713063334166-88d74a94-e8fb-4349-b580-060cff2179e2.png)



生产环境下我们不会直接用 OSS 的 URL 访问，而是会开启 CDN：

+ 当用户通过网站域名请求文件时，请求会被 CDN 服务接收。
+ CDN 会根据用户的地理位置，将请求重定向到最近的缓存服务器。
+ 如果这个服务器上已经缓存了请求的文件，那么文件将直接从该服务器提供给用户，从而减少了数据传输的延迟。
+ 如果缓存服务器上没有文件，它会从原始位置（即 OSS 服务）获取文件，并将其缓存以备后续请求使用。



## Node 上传下载 OSS 图片
### 代码准备
```bash
mkdir oss-test
cd oss-test
npm init -y
```

安装用到的包：

```bash
npm install ali-oss
```

代码：

```javascript
const OSS = require('ali-oss')

const client = new OSS({
    region: 'oss-cn-beijing',
    bucket: 'yun-667',
    accessKeyId: '',
    accessKeySecret: '',
});

async function put () {
  try {
    const result = await client.put('yun.png', './avatar.png');
    console.log(result);
  } catch (e) {
    console.log(e);
  }
}

put();
```

new OSS 的时候有几个选项需要获取。



### 获取 region
region 在概览可以看到：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713065588773-6eb11c42-7367-4244-bb91-e92e28ac80fd.png)



### 获取 accessKey
这里的 accessKeyId 和 acessKeySecret 是什么呢？

阿里云的安全策略建议使用 AccessKey（包括 AccessKeyId 和 AccessKeySecret ）进行身份认证，而不是直接使用用户名和密码。

为了进一步减少安全风险，建议使用 RAM（Resource Access Management）子用户的方式生成 AccessKey，这样可以最小化权限。

我们创建个 accesKey：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713065711517-39e680ae-b5ea-4f24-8910-c351bade5ee7.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713065783833-b596e753-b2dc-4937-b7b3-bd92fdf1fb1e.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713065841257-af42ff96-61fb-451c-8e0c-1b62e9c2d707.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713065903226-4a120289-83f4-4f22-8f24-e2e275237e31.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713070812932-6c081c45-2b4f-443b-934b-ca941f028f02.png)

创建完成后，就可以拿到 accesKeyId 和 accessKeySecret。



### 设置访问控制
![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713070068914-273e2c67-0aa6-4770-87f3-a4df76cc5c76.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713070361977-1b3fe2ed-678e-4f7f-86e9-ff4026a1581a.png)

新增一个授权：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713070386913-6414beb8-f01f-4385-afa3-722b0b2dc099.png)

把 OSS 的管理和读取权限给这个子用户：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713070469064-d8432fee-a61e-45c7-b5c2-e5974ccc06ef.png)



### 运行上传文件代码
node 运行下：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713070770234-165c0bec-04eb-4040-a954-89acfd46f9a3.png)

这时候就上传成功了。

[阿里云的大文件分片上传](https://link.juejin.cn/?target=https%3A%2F%2Fhelp.aliyun.com%2Fzh%2Foss%2Fuser-guide%2Fmultipart-upload)直接看文档就行了。



### 下载图片
![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713108985264-61f435ee-500b-47b7-a80f-d5299492042a.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713108968672-8750cc85-762e-4dd4-b51d-0d8ffd6af311.png)



## OSS 上传方案
在实际应用中，我们可以选择让客户端直接将文件上传至 OSS：

![画板](https://cdn.nlark.com/yuque/0/2024/jpeg/21596389/1713071856598-13a4590b-acc8-437c-9519-71bce0ee406a.jpeg)

也可以先上传至应用服务器，再由应用服务器转发至 OSS。

![画板](https://cdn.nlark.com/yuque/0/2024/jpeg/21596389/1713071691522-5d5b4a1e-8e52-4e7d-bf3d-4dac4aae197d.jpeg)

直接上传可以节省应用服务器的流量，但增加了 accessKey 泄露的风险





有没有什么两全其美的办法？

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713072001471-6a9e6073-1d55-49e5-a5ba-fa1a491cd123.png)

[阿里云的文档](https://link.juejin.cn/?target=https%3A%2F%2Fhelp.aliyun.com%2Fzh%2Foss%2Fuser-guide%2Fauthorized-third-party-upload)里也提到了这个问题。

它给出的解决方案就是生成一个临时的签名来用。

代码是这样的：

```javascript
const OSS = require('ali-oss');

async function main() {
	const config = {
		region: '',
		bucket: '',
		accessKeyId: '',
		accessKeySecret: '',
	};

	const client = new OSS(config);

	const date = new Date();

	date.setDate(date.getDate() + 1);

	const res = client.calculatePostSignature({
		expiration: date.toISOString(),
		conditions: [
			['content-length-range', 0, 1048576000], //设置上传文件的大小限制。
		],
	});

	console.log(res);

	const location = await client.getBucketLocation();

	const host = `http://${config.bucket}.${location.location}.aliyuncs.com`;

	console.log(host);
}

main();
```

获取到了临时凭证的信息：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713072149956-d5c84d57-b613-4164-91e5-975de54f089a.png)  
这样就能在网页里用这些来上传文件到 OSS 了：

创建个 index.html：

```javascript
<!DOCTYPE html>
<html lang="en">
	<head>
		<script src="https://unpkg.com/axios@1.6.5/dist/axios.min.js"></script>
	</head>
	<body>
		<input id="fileInput" type="file" />

		<script>
			const fileInput = document.getElementById('fileInput');

			async function getOSSInfo() {
				// 下面的信息可以通过请求服务器获取
				return {
					OSSAccessKeyId: '',
					Signature: '',
					policy: '',
					host: '',
				};
			}

			fileInput.onchange = async () => {
				const file = fileInput.files[0];

				const ossInfo = await getOSSInfo();

				const formdata = new FormData();

				formdata.append('key', file.name);
				formdata.append('OSSAccessKeyId', ossInfo.OSSAccessKeyId);
				formdata.append('policy', ossInfo.policy);
				formdata.append('signature', ossInfo.Signature);
				formdata.append('success_action_status', '200');
				formdata.append('file', file);

				const res = await axios.post(ossInfo.host, formdata);
				if (res.status === 200) {
					const img = document.createElement('img');
					img.src = ossInfo.host + '/' + file.name;
					document.body.append(img);

					alert('上传成功');
				}
			};
		</script>
	</body>
</html>
```

跑个静态服务器：

```javascript
npx http-server .
```

我们需要在控制台开启下跨域：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713072658449-0d365fb0-6007-440a-818c-f51b3986d738.png)

上传文件：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713072690625-4fd268c2-90ae-4fac-a695-f70d929a9193.png)

上传成功了。

控制台文件列表也可以看到这个文件：  
![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713072932233-9386fc40-4fed-4cb7-bc75-0f8bc4623165.png)

这就是完美的 OSS 上传方案。



服务端用 RAM 子用户的 accessKey 来生成临时签名，然后返回给客户端，客户端用这个来直传文件到 OSS。

因为临时的签名过期时间很短，我们设置的是一天，所以暴露的风险也不大。

这样服务端就根本没有接受文件的压力，只要等客户端上传完之后，带上 URL 就好了。


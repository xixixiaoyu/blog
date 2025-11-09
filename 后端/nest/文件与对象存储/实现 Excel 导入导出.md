## Excel 数据处理简介
Excel 是广泛应用于办公场景的数据处理软件。

在日常开发中，我们常需在后台管理系统中实现数据的导入与导出功能，以便与 Excel 文件进行交互。



## 使用 exceljs 库进行 excel 数据处理
### exceljs 简介
在 Node.js 环境和浏览器中，我们常用 exceljs 这个包来解析和生成 Excel 文件。该包在 npm 官网上每周有超过 30 万的下载量，足见其受欢迎程度。



### 环境搭建
```bash
mkdir exceljs-test
cd exceljs-test
npm init -y
```

安装 exceljs：

```bash
npm install exceljs
```

新建 data.xlsx：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1710680107405-111d150e-e51d-4f57-ba51-96e960061c0e.png)![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1710680134531-057e836b-2139-4895-a6de-b666d1e9f39a.png)



### 从 Excel 文件读取数据
工作表结构遵循层级关系：workbook（工作簿）> worksheet（工作表）> row（行）> cell（单元格）。通过遍历这些层级，我们可以获取所有数据：

```javascript
// 引入 exceljs 库
const { Workbook } = require('exceljs');

// 异步函数读取 Excel 文件
async function main() {
	// 创建一个Workbook实例，用于处理Excel文件
	const workbook = new Workbook();

	// 从指定路径读取Excel文件
	const dataBook = await workbook.xlsx.readFile('./data.xlsx');

	// 遍历Excel中的每个工作表
	dataBook.eachSheet((sheet, index1) => {
		console.log('工作表 ' + index1);

		// 遍历每个工作表中的每行数据
		sheet.eachRow((row, index2) => {
			const rowData = []; // 用于存储当前行的数据

			row.eachCell((cell, index3) => {
				// 遍历当前行的每个单元格，并将值存储到rowData数组中
				rowData.push(cell.value);
			});

			console.log('行 ' + index2, rowData);
		});
	});
}

main();
```

node 运行：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1710680220388-05060a2e-0d6f-41b3-900c-d3ff5c67b49e.png)

我们已经解析出 excel 数据了。





exceljs 还提供了简便的方法，可以直接调用 worksheet 的 getSheetValues 来拿到表格数据，不用自己遍历：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1710680542069-51412896-dadc-4d8c-aa16-e20b6ea0f9e8.png)

这就是解析 excel 文件。

导入数据的时候，按照格式从中解析数据然后存入数据库就行。

一般我们都会提供一个 excel 模版，用这个模版来填数据，然后再导入。  


### 数据导出
使用 exceljs 进行数据导出：

```javascript
const { Workbook } = require('exceljs');

async function main() {
	// 创建一个新的工作簿
	const workbook = new Workbook();
	// 添加一个新的工作表，命名为'hong'
	const worksheet = workbook.addWorksheet('hong');

	// 定义工作表的列结构
	worksheet.columns = [
		{ header: 'ID', key: 'id', width: 20 },
		{ header: '姓名', key: 'name', width: 40 },
		{ header: '年龄', key: 'age', width: 20 },
	];

	// 数据数组，用于填充工作表
	const data = [
		{ id: 1, name: '探春', age: 18 },
		{ id: 2, name: '迎春', age: 19 },
		{ id: 3, name: '惜春' },
	];

	// 向工作表中添加数据行
	worksheet.addRows(data);

	// 将工作簿保存为Excel文件
	workbook.xlsx.writeFile('./data2.xlsx');
}

main();
```

运行后产生的 data2.xlsx 如下：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1710680976319-f388a512-f3bf-4ff7-a771-30dbab220c3a.png)

我们可以遍历行和列，对特定单元格进行样式设置，如字体、背景色、边框等。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1710681224402-e8278182-99f9-42b7-8c4b-f893250962f6.png)

比如通过 cell.style 可以设置 font、fill、border、alignment 这些。





### **在浏览器中使用 ExcelJS 库解析 Excel 文件**
创建 index.html，引入 exceljs 包：

```html
<!DOCTYPE html>
<html lang="en">
	<head>
		<!-- 加载ExcelJS库 -->
		<script src="https://unpkg.com/exceljs@4.4.0/dist/exceljs.min.js"></script>
	</head>
	<body>
		<!-- 文件选择输入框 -->
		<input id="fileInput" type="file" />

		<script>
			const fileInput = document.getElementById('fileInput');

			// 文件选择变化时的处理逻辑
			fileInput.onchange = async () => {
				// 获取选中的文件
				const file = fileInput.files[0];

				const { Workbook } = ExcelJS;

				const workbook = new Workbook();

				const loadedWorkbook = await workbook.xlsx.load(file);

				loadedWorkbook.eachSheet((sheet, index1) => {
					console.log('工作表' + index1);

					const value = sheet.getSheetValues();

					console.log(value);
				});
			};
		</script>
	</body>
</html>
```

启动静态服务器：

```html
npx http-server .
```

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1710681590994-0e51e2bc-2ec9-409a-9925-6ee8a88c175e.png)

同样解析出了 excel 的内容。



### 在浏览器中使用 ExcelJS 库生成 Excel 文件并下载
然后再试试生成 excel：

这里我创建了一个 10M 的 ArrayBuffer 来写入数据，之后再读取。

```html
<!DOCTYPE html>
<html lang="en">
	<head>
		<meta charset="UTF-8" />
		<script src="https://unpkg.com/exceljs@4.4.0/dist/exceljs.min.js"></script>
	</head>
	<body>
		<script>
			const { Workbook } = ExcelJS;

			async function main() {
				// 创建一个新的工作簿
				const workbook = new Workbook();
				// 添加一个新的工作表，命名为'hong'
				const worksheet = workbook.addWorksheet('hong');

				// 定义工作表的列结构
				worksheet.columns = [
					{ header: 'ID', key: 'id', width: 20 },
					{ header: '姓名', key: 'name', width: 40 },
					{ header: '年龄', key: 'age', width: 20 },
				];

				// 数据数组，用于填充工作表
				const data = [
					{ id: 1, name: '宝玉', age: 18 },
					{ id: 2, name: '宝钗', age: 19 },
					{ id: 3, name: '黛玉' },
				];

				worksheet.addRows(data);

				// 将工作簿写入 ArrayBuffer 并下载
				const buffer = new ArrayBuffer(10 * 1024 * 1024); // 分配足够大的内存空间
				const res = await workbook.xlsx.writeBuffer(buffer);

				download(res.buffer);
			}

			function download(arrayBuffer) {
				const link = document.createElement('a');

				// 创建 Blob 对象并生成 URL
				const blob = new Blob([arrayBuffer]);
				const url = URL.createObjectURL(blob);
				link.href = url;
				// 设置下载的文件名
				link.download = 'honglou.xlsx';

				// 插入链接到页面并触发点击下载
				document.body.appendChild(link);

				link.click();
				// 下载完成后移除链接
				link.addEventListener('click', () => {
					link.remove();
				});
			}

			main();

			// 在页面加载完毕后执行
			window.onload = generateExcel;
		</script>
	</body>
</html>
```

和前面的逻辑一样，只是把 writeFile 换成了 writeBuffer。

在浏览器中打开 index.html，Excel 文件将自动生成并下载：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1710682156292-f778bd11-e858-482a-b1ab-257031e1f510.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1710682141976-58d0804d-37d7-4e2b-a304-7f7f1410bc8f.png)


# NestJS 全方位测试指南：从单元测试到 E2E

## 1. 为什么要写自动化测试？

在现代软件开发中，自动化测试是保障代码质量、提升开发效率和增强重构信心的基石。想象一下，你刚改了一行代码，就需要手动点开应用的每个页面、每个功能来确保一切正常。这不仅费时费力，还容易遗漏边缘情况。

自动化测试就像一个不知疲倦的助手，能帮你解决这些问题，其核心优势包括：

*   **提高代码质量与覆盖率**：机器比人更细致，能覆盖更多的代码路径和边界情况，确保每个部分都如预期般工作。
*   **加快反馈速度**：在几秒或几分钟内跑完所有测试，让你能快速发现并定位问题。
*   **降低维护成本**：问题发现得越早，修复成本越低。测试是保证长期项目健康发展的关键。
*   **增强重构信心**：有了完善的测试作为安全网，你可以大胆地进行代码重构和优化，而无需担心引入新的错误。

### NestJS 的测试优势

NestJS 作为一个企业级的 Node.js 框架，从设计之初就将“可测试性”放在了核心位置。它提供的强大支持让开发者能更轻松地编写高质量的测试用例：

*   **基于依赖注入 (DI)**：NestJS 的核心特性是依赖注入，这也让测试变得异常灵活。你可以轻松地在测试环境中替换、模拟任何依赖项，实现对测试目标的精准控制。
*   **自动生成测试骨架**：通过 Nest CLI 创建控制器或服务时，会自动生成对应的测试文件（`.spec.ts`），为你省去手动搭建的麻烦。
*   **内置测试工具**：默认集成 **Jest**（一个功能强大的 JavaScript 测试框架）和 **Supertest**（一个流畅的 HTTP 测试工具），无需额外配置即可开箱即用。
*   **灵活的测试模块**：`@nestjs/testing` 包提供了创建隔离测试环境的能力，让单元测试、集成测试和 E2E 测试的编写都变得轻而易举。

## 2. 测试金字塔：NestJS 的三重境界

在 NestJS 中，我们通常将测试分为三个层次，构成一个“测试金字塔”：

1.  **单元测试 (Unit Tests)**：位于金字塔底座，数量最多。它专注于测试最小的可测试单元（如一个服务类中的某个方法或一个独立的函数），确保其逻辑正确无误。这类测试运行速度最快，隔离性最强。
2.  **集成测试 (Integration Tests)**：位于金字塔中间。它测试多个单元如何协同工作（如一个控制器如何调用一个服务，服务又如何与数据仓库交互）。它确保了组件间的“契约”得到遵守。
3.  **端到端测试 (E2E Tests)**：位于金字塔顶端，数量最少。它从用户的视角出发，通过模拟真实的 HTTP 请求来测试整个应用的完整流程，从请求入口到数据库再到最终响应。

**测试策略**：多写单元测试，它们运行快、定位问题准。适量编写集成测试，确保模块间协作无误。少量编写 E2E 测试，覆盖核心业务流程。

## 3. 环境准备

在开始编写测试之前，请确保你的项目中已安装了必要的开发依赖。如果你的项目是使用 NestJS CLI 创建的，那么这些依赖通常已经为你配置好了。

```bash
npm install --save-dev @nestjs/testing jest supertest @types/jest @types/supertest
```

*   `@nestjs/testing`：提供 NestJS 测试的核心功能，如 `Test.createTestingModule`。
*   `jest`：NestJS 默认的测试运行器和断言库。
*   `supertest`：用于发送 HTTP 请求，是 E2E 和集成测试的利器。

同时，确保 `package.json` 中包含以下脚本：

```json
"scripts": {
  "test": "jest",
  "test:watch": "jest --watch",
  "test:cov": "jest --coverage",
  "test:e2e": "jest --config ./test/jest-e2e.json"
}
```

运行 `npm test` 即可执行所有单元和集成测试。

## 4. 单元测试：深入代码的最小单元

单元测试的目标是 **隔离**。我们只想测试一个独立的单元，而不关心它的依赖项是真实还是模拟的。

### 基础 Service 单元测试

假设我们有一个简单的 `CatsService`，它没有任何外部依赖。

```typescript
// src/cats/cats.service.ts
import { Injectable } from '@nestjs/common';
import { Cat } from './interfaces/cat.interface';

@Injectable()
export class CatsService {
  private readonly cats: Cat[] = [];

  create(cat: Cat) {
    this.cats.push(cat);
  }

  findAll(): Cat[] {
    return this.cats;
  }
}
```

它的单元测试会非常直接：

```typescript
// src/cats/cats.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { CatsService } from './cats.service';

describe('CatsService', () => {
  let service: CatsService;

  // 在每个测试用例运行前执行，确保测试环境的纯净
  beforeEach(async () => {
    // 使用 NestJS 提供的测试模块创建器
    const module: TestingModule = await Test.createTestingModule({
      providers: [CatsService], // 声明我们需要测试的提供者
    }).compile();

    // 从编译好的模块中获取 service 实例
    service = module.get<CatsService>(CatsService);
  });

  it('should be defined', () => {
    // 最基本的测试：检查 service 是否被成功创建
    expect(service).toBeDefined();
  });

  it('should create a new cat', () => {
    const newCat = { name: 'Tom', age: 3, breed: 'Short Hair' };
    service.create(newCat);
    
    // 断言：检查 cats 数组中是否包含了我们刚创建的猫
    expect(service.findAll()).toContainEqual(newCat);
  });
});
```

**核心思路**：`Test.createTestingModule` 创建了一个微型的 NestJS 模块，只包含我们需要的 `CatsService`。这样，我们就可以在一个纯净的环境中测试它的内部逻辑，不受外界干扰。

### 模拟依赖的单元测试

在真实场景中，Service 通常会依赖其他服务或 Repository。在单元测试中，我们必须 **模拟（Mock）** 这些依赖项，以保持测试的独立性。

假设 `CatsService` 依赖于 `CatsRepository` 来操作数据库。

```typescript
// src/cats/cats.service.ts
import { Injectable } from '@nestjs/common';
import { CatsRepository } from './cats.repository';

@Injectable()
export class CatsService {
  constructor(private readonly catsRepository: CatsRepository) {}

  async findAll(): Promise<any[]> {
    return this.catsRepository.findAll();
  }
}
```

在测试 `CatsService` 时，我们不希望它真的去调用数据库。因此，我们需要提供一个假的 `CatsRepository`。

```typescript
// src/cats/cats.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { CatsService } from './cats.service';
import { CatsRepository } from './cats.repository';

// 创建一个模拟的 Repository 对象
const mockCatsRepository = {
  findAll: jest.fn(), // 使用 jest.fn() 创建一个模拟函数
};

describe('CatsService', () => {
  let service: CatsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CatsService,
        {
          provide: CatsRepository, // 当需要注入 CatsRepository 时
          useValue: mockCatsRepository, // 提供我们的模拟对象
        },
      ],
    }).compile();

    service = module.get<CatsService>(CatsService);
  });

  it('should return an array of cats', async () => {
    const result = [{ name: 'Tom', age: 2, breed: 'Short Hair' }];
    // 让模拟的 findAll 方法在被调用时返回一个预设的值
    mockCatsRepository.findAll.mockResolvedValue(result);

    // 调用 service 的方法，它内部会调用模拟的 repository
    expect(await service.findAll()).toBe(result);
    // 断言模拟函数被调用过
    expect(mockCatsRepository.findAll).toHaveBeenCalled();
  });
});
```

**核心思路**：通过在 `providers` 数组中使用 `{ provide: RealClass, useValue: mockObject }` 的语法，NestJS 的 DI 系统会在创建 `CatsService` 实例时，自动注入我们提供的 `mockCatsRepository`，而不是真实的 `CatsRepository`。这让我们完全掌控了依赖的行为。

## 5. 集成测试：检验组件间的协作

集成测试关注的是多个组件如何协同工作。例如，一个 HTTP 请求到达 `CatsController` 后，`CatsController` 是否正确地调用了 `CatsService`。

在集成测试中，我们通常会创建包含多个真实组件的测试模块，但可能会模拟最外层的依赖（如数据库或第三方 API）。

### Controller 集成测试

测试 `CatsController` 时，我们想验证它能否正确处理路由、调用 `CatsService` 并返回预期的结果。

```typescript
// src/cats/cats.controller.spec.ts
import { Test } from '@nestjs/testing';
import { CatsController } from './cats.controller';
import { CatsService } from './cats.service';

// 模拟 CatsService
const mockCatsService = {
  findAll: jest.fn().mockReturnValue([{ name: 'Tom', breed: 'Test Cat' }]),
  create: jest.fn().mockImplementation(cat => ({ id: Date.now(), ...cat })),
};

describe('CatsController', () => {
  let controller: CatsController;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      controllers: [CatsController],
      providers: [
        {
          provide: CatsService,
          useValue: mockCatsService,
        },
      ],
    }).compile();

    controller = module.get<CatsController>(CatsController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('should return an array of cats', () => {
    expect(controller.findAll()).toEqual([{ name: 'Tom', breed: 'Test Cat' }]);
    expect(mockCatsService.findAll).toHaveBeenCalled();
  });

  it('should create a cat', () => {
    const createCatDto = { name: 'Kitty', age: 1, breed: 'Persian' };
    const result = controller.create(createCatDto);
    
    expect(result).toEqual({ id: expect.any(Number), ...createCatDto });
    expect(mockCatsService.create).toHaveBeenCalledWith(createCatDto);
  });
});
```

**核心思路**：这个测试与单元测试非常相似，但焦点不同。我们不再关心 `CatsService` 的内部实现，而是把它当作一个黑盒。我们只验证 `CatsController` 在接收到输入后，是否正确地与 `CatsService` 进行了交互（即调用了正确的方法并传递了正确的参数）。

## 6. 端到端 (E2E) 测试：模拟真实用户

E2E 测试是最高层次的测试，它模拟真实用户的行为，从发送 HTTP 请求开始，贯穿整个应用，直到收到响应。它不关心内部实现细节，只关心输入和输出。

NestJS 结合 `supertest` 库，让 E2E 测试变得非常简单。

```typescript
// test/app.e2e-spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from './../src/app.module';

describe('AppController (e2e)', () => {
  let app: INestApplication;

  // 在所有测试开始前，创建一次完整的 NestJS 应用实例
  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule], // 导入真实的根模块
    }).compile();

    app = moduleFixture.createNestApplication();
    // 推荐：让测试环境与生产环境尽可能一致，比如启用全局管道
    app.useGlobalPipes(new ValidationPipe());
    await app.init(); // 初始化应用，但不绑定网络端口
  });

  // 所有测试结束后，关闭应用，释放资源
  afterAll(async () => {
    await app.close();
  });

  it('/ (GET)', () => {
    return request(app.getHttpServer()) // 获取底层 HTTP 服务器
      .get('/') // 发送 GET 请求
      .expect(200) // 断言状态码
      .expect('Hello World!'); // 断言响应体
  });

  describe('/cats', () => {
    it('POST /cats -> should create a new cat', () => {
      const catDto = { name: 'Garfield', age: 3, breed: 'Persian' };
      return request(app.getHttpServer())
        .post('/cats')
        .send(catDto) // 发送请求体
        .expect(201) // 断言状态码为 Created
        .then(response => {
          // 对响应体做更详细的断言
          expect(response.body).toEqual({
            id: expect.any(Number),
            ...catDto,
          });
        });
    });

    it('POST /cats -> should return 400 for invalid data', () => {
      const invalidDto = { name: 'Garfield' }; // 缺少 age 和 breed
      return request(app.getHttpServer())
        .post('/cats')
        .send(invalidDto)
        .expect(400); // 断言为 Bad Request
    });

    it('GET /cats -> should return an array of cats', () => {
        return request(app.getHttpServer())
            .get('/cats')
            .expect(200)
            .expect(res => {
                expect(res.body).toBeInstanceOf(Array);
            });
    });
  });
});
```

**核心思路**：E2E 测试会在测试环境中初始化一个完整的 NestJS 应用。应用通过 `app.init()` 完成初始化，而不调用 `app.listen()`，因此不会占用任何网络端口。我们使用 `supertest` 来模拟 HTTP 客户端，发送请求并验证响应的状态码、头部和响应体是否符合预期。这种测试最接近真实用户场景，能提供最强的信心。

## 7. 进阶技巧与最佳实践

### 进阶技巧

*   **覆盖全局守卫/拦截器**：在测试中，你可能需要绕过认证或日志记录等全局逻辑。
    ```typescript
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideGuard(AuthGuard) // 覆盖全局守卫
      .useValue({ canActivate: () => true }) // 提供一个总是允许访问的假守卫
      .compile();
    ```
*   **测试请求作用域的服务**：对于请求作用域（Request-Scoped）的提供者，你需要使用 `module.resolve()` 并传递一个上下文 ID 来获取实例。
    ```typescript
    const contextId = ContextIdFactory.create();
    const service = await module.resolve(RequestScopedService, contextId);
    ```

### 最佳实践

1.  **保持测试独立 (AAA 模式)**：每个测试用例都应遵循 Arrange（准备）、Act（执行）、Assert（断言）的模式，并且能独立运行，不依赖其他测试的结果。
2.  **使用描述性的测试名称**：测试名称应清晰地描述它正在测试的行为，如 `should return an array of cats`，让测试本身成为一种文档。
3.  **模拟所有外部依赖**：在单元和集成测试中，所有外部依赖（如数据库、第三方 API、文件系统）都应该被模拟，以确保测试的稳定、快速和可预测。
4.  **一个测试只验证一件事**：避免在一个 `it` 块中编写过于复杂的逻辑和多个断言。保持测试的专注和简洁。
5.  **善用 `beforeEach` 和 `afterAll`**：使用 `beforeEach` 来创建干净的测试环境，使用 `afterAll` 或 `afterEach` 来清理资源（如关闭数据库连接或应用实例），避免测试间的相互影响。
6.  **为 E2E 测试使用独立的测试数据库**：为了避免污染开发或生产数据，并确保测试环境的隔离，E2E 测试应该连接到一个独立的、可随时清空的测试数据库。

## 8. 总结

自动化测试不是开发的负担，而是一项保障项目长期健康、提升团队信心的重要投资。NestJS 凭借其强大的依赖注入系统和完善的测试工具链，为我们构建健壮、可靠的应用程序提供了坚实的基础。

通过掌握单元测试、集成测试和 E2E 测试这三重境界，并遵循最佳实践，你可以为你的 NestJS 项目构建一个全面的测试体系，从而在快速迭代的同时，高枕无忧地交付高质量的代码。

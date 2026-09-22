# Simplification

支持 Swift 5.7+ 和 Swift 6 的依赖注入容器，支持 iOS 13+、macOS 10.15+。最低工具链为 Swift 5.7（Xcode 14）。Swift 5 工具链使用 Swift 5 语言模式，Swift 6 工具链自动使用 Swift 6 严格并发模式。

## 安装与发布

工程已包含 Swift Package Manager 清单，可通过 Xcode 添加本地 Package 使用。远程版本尚未发布；确定仓库地址及版本标签后，即可通过仓库 URL 添加依赖。

CocoaPods 配置模板见 `Simplification.podspec.template`。发布准备、验证和上传步骤见 [发布说明](RELEASING.md)。

## 使用

容器、工厂和属性包装器统一由 `@MainActor` 隔离。主 actor 内同步注册、解析，适合 SwiftUI 和其他 UI 依赖。容器不要求服务实现 `Sendable`。

```swift
import Simplification

@MainActor
final class Service {
    func refresh() {}
}

@MainActor
func configureDependencies() {
    Simplification.shared.register(Service.self, lifeCycle: .lazySingleton) {
        Service()
    }
}

@MainActor
final class Controller {
    @Injected var service: Service

    func refresh() {
        service.refresh()
    }
}
```

SwiftUI 中，对 `ObservableObject` 使用 `@InjectedObject`；其 `$property` 提供可观察属性的 Binding。包装器使用 `ObservedObject`，不会为 transient 服务保证视图重建期间的对象身份；需要稳定身份时使用单例生命周期，或由外部所有者持有对象。

可以通过 `Simplification()` 创建独立容器，并以 `@Injected(container: container)` 或包装器初始化参数指定容器。注册同一类型会完整替换之前的工厂和缓存。

## 生命周期

| 生命周期 | 创建时机 | 保留方式 |
| --- | --- | --- |
| `singleton` | 注册时 | 强引用 |
| `lazySingleton` | 首次解析 | 强引用 |
| `autoRelease`（默认） | 首次解析及外部引用全部释放后 | 类实例使用弱引用；值类型使用强引用 |
| `transient` | 每次解析 | 不缓存 |

`lazyPut` 默认使用 `autoRelease`；传入 `autoRelease: false` 则使用 `lazySingleton`。`Injected` 每次读取都会解析，遵循所注册的生命周期。

工厂可以同步解析其他依赖。未注册的类型、循环依赖、在工厂执行期间重新注册正在构建的类型，会触发带诊断信息的前置条件失败。工厂应避免阻塞主线程；异步初始化应在工厂外完成。

## Swift 6 迁移

原来的自定义 actor 已改为 `@MainActor final class`，移除了手动锁与 `@unchecked Sendable`。调用方需要在主 actor 内访问；后台任务可以通过 `await` 调用容器，但返回值只有满足 `Sendable` 才能跨隔离域传递。非 Sendable 服务应在 `MainActor.run` 内解析并使用，仅返回可传递的结果。

```swift
let result = await MainActor.run {
    let service: Service = Simplification.shared.resolve()
    service.refresh()
    return "finished"
}
```

存储用的 `DependencyStrong` 枚举已移除，类型键使用 `ObjectIdentifier`，避免同名类型冲突。

测试使用 XCTest，不依赖 Swift 6 才内置的 Swift Testing。两种语言模式使用相同的主 actor 隔离规则和公开 API。

## 可运行示例

打开 `Examples/SimplificationDemos.xcodeproj`，选择 `UIKitDemo` 或 `SwiftUIDemo` Scheme 即可运行。两个示例展示名字绑定、计数操作与跨页面共享依赖，详见 [示例说明](Examples/README.md)。

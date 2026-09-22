# Simplification

支持 Swift 5.7+ 和 Swift 6 的依赖注入容器，支持 iOS 13+、macOS 10.15+。最低工具链为 Swift 5.7（Xcode 14）。Swift 5 工具链使用 Swift 5 语言模式，Swift 6 工具链自动使用 Swift 6 严格并发模式。

## 集成

CocoaPods 和 Swift Package Manager（SPM）任选一种，避免在同一 Target 中重复引入。以下版本示例使用 `0.0.1`：远程集成需要仓库已推送对应标签；通过 CocoaPods 公共源安装还需要完成 Trunk 发布。尚未发布时可使用本地路径集成。

### CocoaPods

在应用工程的 `Podfile` 中添加依赖，将 `YourApp` 替换为实际 Target 名称：

```ruby
  pod 'Simplification', '~> 0.0.1'
```

在 `Podfile` 所在目录执行：

```sh
pod install
```

安装完成后打开生成的 `.xcworkspace` 文件进行开发。

如果尚未发布到 CocoaPods 公共源，可将上述 `pod` 行替换为 Git 标签依赖（远程仓库必须包含 podspec 和该标签）：

```ruby
pod 'Simplification', :git => 'https://github.com/jtyXcode/Simplification.git', :tag => '0.0.1'
```

本地开发时，也可替换为路径依赖；路径相对于 `Podfile`，应指向包含 `Simplification.podspec` 的目录：

```ruby
pod 'Simplification', :path => '../Simplification'
```

以上三种 `pod` 声明只保留一种。修改后重新运行 `pod install`。macOS 工程将平台声明改为 `platform :osx, '10.15'`。

### Swift Package Manager（SPM）

**通过 Xcode 集成**

1. 打开应用工程，选择 **File → Add Package Dependencies…**。
2. 输入仓库地址：`https://github.com/jtyXcode/Simplification.git`。
3. 选择 **Up to Next Minor Version**，起始版本填写 `0.0.1`。
4. 点击 **Add Package**，将 `Simplification` 产品添加到需要使用它的应用 Target。

本地开发时，在添加 Package 的窗口中选择 **Add Local…**，选中包含 `Package.swift` 的 Simplification 根目录，再将 `Simplification` 产品添加到应用 Target。

**通过 Package.swift 集成**

如果使用方本身也是 Swift Package，在现有 `Package.swift` 的包依赖和 Target 依赖中分别添加：

```swift
dependencies: [
    .package(
        url: "https://github.com/jtyXcode/Simplification.git",
        .upToNextMinor(from: "0.0.1")
    )
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "Simplification", package: "Simplification")
        ]
    )
]
```

将 `YourTarget` 替换为实际 Target 名称，并合并到现有配置中。本地集成时，将 `.package(url: …)` 声明替换为 `.package(path: "../Simplification")`；路径相对于使用方的包根目录。使用方的平台最低版本应为 iOS 13 或 macOS 10.15。

### 导入与调用

两种方式集成后均使用 `import Simplification`。容器 API 由 `@MainActor` 隔离，注册和解析应在主 actor 中执行，完整示例见下方「使用」。


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

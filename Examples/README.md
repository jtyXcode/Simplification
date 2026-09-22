# UIKit / SwiftUI 使用 Demo

用 Xcode 打开 `SimplificationDemos.xcodeproj`，选择 Scheme 和 iPhone 模拟器，按 **⌘R**：

| Scheme | 最低系统 | 主要 API |
| --- | --- | --- |
| UIKitDemo | iOS 13 | `@Injected` |
| SwiftUIDemo | iOS 14 | `@InjectedObject`、`$store.name` |

工程通过本地 Swift Package 引用上一级目录的框架，无需安装第三方依赖。默认 Swift 5 语言模式；使用 Swift 6 工具链时，也可以将 target 的 **Swift Language Version** 改为 **Swift 6**。真机运行需要在 Signing & Capabilities 中选择自己的 Team。

## 可以体验什么

1. 修改名字：问候文本跟随变化。
2. 点击“加 1”或“重置”：更新计数。
3. 打开第二页：实例 ID 与第一页相同。
4. 在第二页增加计数并返回：验证两页共享同一个 `lazySingleton`。

两个 App 是独立进程，各自拥有独立的容器和状态。

## 代码入口

- `Shared/DemoDependencies.swift`：协议服务注册、立即单例、懒加载单例，以及工厂内解析其他依赖。
- `UIKitDemo/AppDelegate.swift`：创建控制器之前注册依赖。
- `UIKitDemo/CounterViewController.swift`：使用 `@Injected` 获取状态，手动刷新 UIKit 视图。
- `SwiftUIDemo/SwiftUIDemoApp.swift`：在 App 初始化时注册依赖。
- `SwiftUIDemo/ContentView.swift`：使用 `@InjectedObject` 观察变化，并通过 `$store.name` 绑定输入框。

所有 UI 和服务都在 `@MainActor` 内访问。SwiftUI 示例采用 `lazySingleton` 保证视图重建时状态稳定；如果改为 `transient`，每次包装器重新初始化都会拿到新的对象。

SwiftUI App 生命周期需要 iOS 14，框架本身及 UIKit Demo 仍支持 iOS 13。示例使用内存状态，退出 App 后不保留计数。

## 命令行构建

在仓库根目录运行（可将 `UIKitDemo` 替换为 `SwiftUIDemo`）：

```sh
xcodebuild -project Examples/SimplificationDemos.xcodeproj \
  -scheme UIKitDemo -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/SimplificationDemo \
  CODE_SIGNING_ALLOWED=NO build
```

使用 Swift 6 工具链时，追加 `SWIFT_VERSION=6.0` 可验证 Swift 6 模式。

## 本地 Package 引用

工程的本地 Package 路径为 `..`（相对于 `Examples`），两个 target 按产品名 `Simplification` 链接。内嵌 workspace 的 `contents.xcworkspacedata` 应随工程一起保留。

如果 Xcode 在修改工程引用之前已打开此工程，请关闭工程窗口后重新打开 `SimplificationDemos.xcodeproj`，使其重新读取产品关联。若仍显示旧的依赖错误，可执行 **File → Packages → Resolve Package Versions** 后重新构建。

import Simplification
import SwiftUI

@MainActor
struct ContentView: View {
    @InjectedObject private var store: CounterStore

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("属性绑定")) {
                    // The wrapper's projected value exposes ObservedObject bindings.
                    TextField("输入名字", text: $store.name)
                        .accessibilityIdentifier("nameField")
                    Text(store.greeting)
                }
                Section(header: Text("共享计数")) {
                    Text("\(store.count)")
                        .font(.system(size: 60, weight: .bold))
                        .accessibilityIdentifier("counterValue")
                    Button("加 1") { store.increment() }
                    Button("重置") { store.reset() }
                    NavigationLink("打开第二页", destination: SharedCounterView())
                }
                Section(header: Text("依赖注入")) {
                    Text("@InjectedObject 自动观察 @Published 的变化。两个页面通过 lazySingleton 共享状态。")
                    Text("实例：\(store.instanceID)").font(.caption)
                }
            }
            .navigationTitle("SwiftUI 注入示例")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

@MainActor
private struct SharedCounterView: View {
    @InjectedObject private var store: CounterStore

    var body: some View {
        Form {
            Text(store.greeting)
            Text("当前计数：\(store.count)")
            Button("在第二页加 1") { store.increment() }
            Text("实例：\(store.instanceID)").font(.caption)
            Text("返回首页后，可以看到同步更新的计数。")
        }
        .navigationTitle("共享状态")
    }
}

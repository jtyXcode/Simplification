import Simplification
import UIKit

@MainActor
final class CounterViewController: UIViewController {
    // A plain UIKit controller resolves the registered object on access.
    @Injected private var store: CounterStore
    private let isDetail: Bool
    private let greetingLabel = UILabel()
    private let countLabel = UILabel()
    private let nameField = UITextField()

    init(isDetail: Bool = false) {
        self.isDetail = isDetail
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("Use init(isDetail:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = isDetail ? "共享状态" : "UIKit 注入示例"
        view.backgroundColor = .systemBackground
        greetingLabel.font = .preferredFont(forTextStyle: .title2)
        greetingLabel.numberOfLines = 0
        countLabel.font = .systemFont(ofSize: 60, weight: .bold)
        countLabel.textAlignment = .center
        countLabel.accessibilityIdentifier = "counterValue"
        nameField.borderStyle = .roundedRect
        nameField.placeholder = "输入名字"
        nameField.accessibilityIdentifier = "nameField"
        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)

        let explanation = UILabel()
        explanation.numberOfLines = 0
        explanation.font = .preferredFont(forTextStyle: .subheadline)
        explanation.textColor = .secondaryLabel
        explanation.text = "@Injected 解析同一个 lazySingleton。打开第二页，计数与实例 ID 保持一致。\n实例：\(store.instanceID)"
        let stack = UIStackView(arrangedSubviews: [
            greetingLabel, nameField, countLabel,
            button("加 1", action: #selector(increment)),
            button("重置", action: #selector(reset)), explanation
        ])
        if !isDetail {
            stack.addArrangedSubview(button("打开第二页", action: #selector(showDetail)))
        }
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        ])
        render()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // UIKit explicitly refreshes after returning from the shared-state page.
        render()
    }

    private func button(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func render() {
        greetingLabel.text = store.greeting
        countLabel.text = "\(store.count)"
        if nameField.text != store.name { nameField.text = store.name }
    }

    @objc private func nameChanged() { store.name = nameField.text ?? ""; render() }
    @objc private func increment() { store.increment(); render() }
    @objc private func reset() { store.reset(); render() }
    @objc private func showDetail() {
        navigationController?.pushViewController(CounterViewController(isDetail: true), animated: true)
    }
}

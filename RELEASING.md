# 发布 Simplification

## 发布信息

作者：`JTY`；邮箱：`1422025039@qq.com`；首发版本：`0.0.1`；许可证：`MIT`。Git 仓库地址待提供。
`Simplification.podspec.template` 是待填写的模板，不能直接发布。

1. 填写模板中的 `REPOSITORY_URL` 和 `REPOSITORY_GIT_URL`，将文件改名为 `Simplification.podspec`。
2. 确认根目录中的 MIT `LICENSE` 文件和作者信息。
3. 仓库根目录必须包含 `Package.swift`、`Sources`、`Tests`、`Simplification.podspec` 和 `LICENSE`。

## 本地验证

```sh
swift test
swift test -Xswiftc -swift-version -Xswiftc 5
pod lib lint Simplification.podspec --swift-version=5.7
pod lib lint Simplification.podspec --swift-version=6.0
```

Swift 5 语言模式测试不能替代使用真正的 Swift 5.7 工具链验证。

## Git 与 SPM

将源码提交并推送到目标 Git 仓库，然后创建与 podspec 版本完全相同的语义化版本标签 `0.0.1`，并推送标签。发布后不要移动已有标签；修复应使用新版本。

SPM 不需要上传到 CocoaPods 或单独的中央仓库。在 Xcode 的 **File → Add Package Dependencies** 中输入 Git 仓库地址，选择对应版本，并添加 `Simplification` 产品。

## CocoaPods

确认公开仓库及版本标签可访问后执行：

```sh
pod spec lint Simplification.podspec --swift-version=5.7
pod spec lint Simplification.podspec --swift-version=6.0
pod trunk me
pod trunk push Simplification.podspec
```

如果没有有效的 Trunk 会话，使用 `pod trunk register EMAIL NAME` 注册，并完成邮件验证。已存在的同名 Pod 需要拥有者权限。

发布成功后，使用方可以在 Podfile 中添加 `pod 'Simplification', '~> VERSION'`（替换为实际版本），然后执行 `pod install`。

参考：[CocoaPods Trunk](https://guides.cocoapods.org/making/getting-setup-with-trunk.html)、[Apple Swift Package 发布说明](https://developer.apple.com/documentation/xcode/publishing-a-swift-package-with-xcode)。

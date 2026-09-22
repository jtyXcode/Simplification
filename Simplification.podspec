Pod::Spec.new do |s|
  s.name             = 'Simplification'
  s.version          = '0.0.2'
  s.summary          = 'A main-actor-isolated dependency injection container for Swift.'
  s.description      = <<-DESC
    A lightweight dependency injection container with singleton, lazy singleton,
    automatic release and transient lifecycles, plus SwiftUI property wrappers.
  DESC
  s.homepage         = 'https://github.com/jtyXcode/Simplification'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'JTY' => '1422025039@qq.com' }
  s.source           = { :git => 'https://github.com/jtyXcode/Simplification.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.swift_versions   = ['5.7', '6.0']
  s.source_files     = 'Sources/Simplification/**/*.swift'
end

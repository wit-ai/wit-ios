Pod::Spec.new do |s|
  s.name         = "Wit"
  s.version      = "4.2.1"
  s.summary      = "Wit.AI Official SDK"
  s.description  = <<-DESC
                     Official Wit SDK, https://wit.ai/docs/ios-tutorial/
                   DESC
  s.homepage     = "https://github.com/wit-ai/wit-ios-sdk"
  s.author       = { "Willy Blandin" => "willy@wit.ai" }
  s.source       = { :git => "https://github.com/wit-ai/wit-ios-sdk.git", :tag => "4.2.1" }

  s.platform = :ios, '7.0'
  s.ios.deployment_target = "7.0"
  s.license = { :type => 'MIT', :file => 'LICENSE' }

  s.requires_arc = true
  s.frameworks = 'QuartzCore','CoreTelephony', 'AudioToolbox'
  s.weak_frameworks = 'Speech'
  s.dependency 'GCNetworkReachability', '~> 1.3'
  s.source_files = 'Classes', 'Classes/**/*.{h,m}', 'Wit/*.{h,m}'
  s.preserve_path = 'WitResources/Images'
  s.resources = ['WitResources/Images/*.png']
end

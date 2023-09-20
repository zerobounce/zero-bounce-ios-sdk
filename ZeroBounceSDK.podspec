Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '9.0'
s.name = "ZeroBounceSDK"
s.summary = "ZeroBounceSDK provides wrappers over ZeroBounce API"
s.requires_arc = true

# 2
s.version = "0.1.7"

# 3
s.license = { :type => "MIT", :file => "LICENSE.md" }

# 4 - Replace with your name and e-mail address
s.author = { "Zero Bounce" => "integrations@zerobounce.net" }

# 5 - Replace this URL with your own GitHub page's URL (from the address bar)
s.homepage = "https://github.com/zerobounce/zero-bounce-ios-sdk"

# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/zerobounce/zero-bounce-ios-sdk.git",
:tag => "#{s.version}" }

# 7
s.framework = "Foundation"

# 8
s.source_files = "Zero Bounce iOS SDK/*.{swift}"

# 9
# s.resources = "ZeroBounceSDK/**/*.{png,jpeg,jpg,storyboard,xib,xcassets}"

# 10
s.swift_version = "5"

# 11
s.readme = "https://github.com/zerobounce/zero-bounce-ios-sdk/blob/#{s.version}/documentation.md"

end

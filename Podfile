platform :ios, '15.0'

target 'Zero Bounce iOS SDK' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Zero Bounce iOS SDK

  target 'Zero Bounce iOS SDKTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'Mocker', '~> 2.5.4'
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end

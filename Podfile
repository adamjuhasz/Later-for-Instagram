# Uncomment this line to define a global platform for your project
# platform :ios, '6.0'

source 'https://github.com/CocoaPods/Specs.git'

target 'later' do
  pod 'InstagramKit', :git => 'https://github.com/adamjuhasz/InstagramKit.git'
  pod "PhotoManager", :path => "../PhotoManager"
  pod 'DACircularProgress'
  pod 'pop',  :git => 'https://github.com/facebook/pop.git'
  pod 'SimpleExif'
  pod 'MMTweenAnimation'
end

target 'laterTests' do

end

post_install do | installer |
  require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods-later/Pods-later-Acknowledgements.plist', 'later/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
    end


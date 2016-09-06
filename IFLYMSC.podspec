Pod::Spec.new do |s|
  s.name             = 'IFLYMSC'
  s.version          = '0.0.1'
  s.summary          = 'IFLYMSC.'
  s.description      = <<-DESC
		       IFLYMSC.
                       DESC

  s.homepage         = 'https://github.com/idavy/IFLYMSC'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'idavy' => 'aidave@126.com' }
  s.source           = { :git => 'https://github.com/idavy/IFLYMSC.git', :tag => s.version.to_s }
  s.ios.deployment_target = '7.0'

  s.source_files = 'IFLYMSC/**/*.{h,m}'
  
  # s.resource_bundles = {
  #   'ProjectBase' => ['ProjectBase/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
    s.preserve_paths = 'iflyMSC.framework'
    s.xcconfig = { 'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/IFLYMSC/Framework/' }
    s.frameworks = 'iflyMSC', 'SystemConfiguration', 'AVFoundation', 'CoreTelephony', 'AudioToolbox', 'AddressBook', 'QuartzCore', 'CoreGraphics'
    s.libraries = 'z'
 					
end

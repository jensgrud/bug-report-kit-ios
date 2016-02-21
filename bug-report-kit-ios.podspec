Pod::Spec.new do |s|
  s.name = 'bug-report-kit-ios'
  s.version = '0.1'
  s.license = 'Unlicensed'
  s.summary = 'Seameless app bug reporting library'
  s.homepage = 'https://github.com/jensgrud/bug-report-kit-ios'
  s.authors = { 'Jens Grud' => 'jdgrud@gmail.com' }
  s.source = { :git => 'https://github.com/jensgrud/bug-report-kit-ios.git', :tag => s.version }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'

  s.source_files = 'bug-report-kit-ios/*.{h,m}'
  s.requires_arc = true

  s.dependency 'CocoaLumberjack', '~> 2.2.0'
end

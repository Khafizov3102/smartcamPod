Pod::Spec.new do |s|
  s.name         = 'smartcamPod'
  s.version      = '1.0.0'
  s.license      = 'MIT'
  s.summary      = 'smartcamPod.'
  s.homepage     = 'https://github.com/Khafizov3102/smartcamPod'
  s.author       = { 'Denis Khafizov' => 'khafizov.den@yandex.ru' }

  s.source = { :git => 'https://github.com/Khafizov3102/smartcamPod.git', :tag => s.version.to_s }
  s.source_files  = 'Sources/**/*'
end

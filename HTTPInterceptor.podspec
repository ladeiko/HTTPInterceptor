Pod::Spec.new do |s|

  s.name         = "HTTPInterceptor"
  s.version      = "1.0.1"
  s.summary      = "HTTPInterceptor - code to intercept http requests and reply with custom response"

  s.homepage         = "https://github.com/ladeiko/HTTPInterceptor"
  s.license          = 'MIT'
  s.authors           = { "Siarhei Ladzeika" => "sergey.ladeiko@gmail.com" }
  s.source           = { :git => "https://github.com/ladeiko/HTTPInterceptor.git", :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.requires_arc = true
  s.static_framework      = true

  s.source_files  =  "Sources/*.{h,m}"
  s.frameworks    = "CoreServices"

end

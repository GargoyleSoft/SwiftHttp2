Pod::Spec.new do |s|
  s.name         = "SwiftHttp2"
  s.version      = "0.0.2"
  s.summary      = "An implementation of HTTP/2 in Swift"
  s.homepage     = "https://github.com/GargoyleSoft/SwiftHttp2"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.authors            = { "Gargoyle Software" => "support@gargoylesoft.com" }
  s.platform     = :osx, "10.12"
  s.source       = { :git => "https://github.com/GargoyleSoft/SwiftHttp2.git", :tag => "#{s.version}" }
  s.source_files  = "SwiftHttp2/**/*.swift"
  s.exclude_files = "SwiftHttp2/ApnsAuthHeader.swift"
end

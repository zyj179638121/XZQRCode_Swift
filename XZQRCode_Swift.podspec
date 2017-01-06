Pod::Spec.new do |s|

  s.name         = "XZQRCode_Swift"
  s.version      = "1"
  s.summary      = "XZQRCode_Swift."

  s.description  = <<-DESC
                    this is XZQRCode_Swift
                   DESC

  s.homepage     = "https://github.com/zyj179638121/XZQRCode_Swift"

  s.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  s.author       = { "zyj179638121" => "179638121@qq.com" }

  s.platform     = :ios, "8.0"

  s.source       = { :git => "git@github.com:zyj179638121/XZQRCode_Swift.git", :tag => s.version.to_s }

  s.source_files  = "XZQRCode_Swift/XZQRCode_Swift/*.swift"

  s.resource  = "XZQRCode_Swift/Assets.xcassets"

  s.requires_arc = true

  s.framework    = "AVFoundation"

end

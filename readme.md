XZQRCode_Swift
====
### 包含UI界面的轻量级二维码扫描框架
## OC版本
OC版本的二维码扫描请移步[XZQRCode_OC](https://github.com/zyj179638121/XZQRCode_OC.git)

## 集成说明
你可以在`Podfile`中加入下面一行代码来使用`XZQRCode_Swift`

	pod 'XZQRCode_Swift'
	
你也可以手动添加源码使用本项目，将开源代码中的`XZQRCode.swift`和`XZQRCodeController.swift`添加到你的工程中。

## 使用说明
如果是用`CocoaPods`集成的,则需要在使用的类里面`import XZQRCodeController`,然后在使用的地方加入如下代码,相应的逻辑在闭包里面进行处理。

```Swift
	let scan = XZQRCodeController.scanner { (result) in
		print("result = \(result)")
  	}
  	show(scan, sender: nil);

```
//
//  XZQRCodeController.swift
//  XZQRCode_Swift
//
//  Created by MYKJ on 17/1/6.
//  Copyright © 2017年 zhaoyongjie. All rights reserved.
//

import UIKit

class XZQRCodeController: UIViewController {
    
    /// 扫描二维码，handle回调内返回扫描结果
    /// 返回值为QRCodeScanner类型对象
    open class func scanner(_ handle: @escaping (String) -> ()) -> XZQRCodeController {
        let sc = XZQRCodeController()
        weak var weakSC = sc
        weakSC?.scanImageFinished = handle
        weakSC?.scanner.prepareScan(sc.view) {
            weakSC?.dissmissVC()
            handle($0)
        }
        return sc
    }
    
    /// 创建二维码图片
    /// 参数：字符串，内嵌图片，内嵌占比，二维码前景色，二维码后景色
    /// 返回值为UIImage?
    open class func createQRCodeImage(_ withStringValue: String, avatarImage: UIImage? = nil, avatarScale: CGFloat? = nil, color: CIColor = CIColor(color: UIColor.black), backColor: CIColor = CIColor(color: UIColor.white)) -> UIImage? {
        return XZQRCode.generateImage(withStringValue, avatarImage: avatarImage, avatarScale: avatarScale ?? 0.25, color: color, backColor: backColor)
    }
    
    fileprivate var scanImageStringValue: String? {
        didSet {
            if let value = scanImageStringValue {
                scanImageFinished!(value)
            }
        }
    }
    
    fileprivate var scanImageFinished: ((String) -> ())?
    
    fileprivate let scanner = XZQRCode()
    
    fileprivate var animating = true
    
    /// MARK: - UI布局
    fileprivate lazy var scanViewHeight: CGFloat = {
        return self.view.frame.width * 0.75
    }()
    
    fileprivate lazy var backgroundView: UIView = {
        self.view.layoutIfNeeded()
        let aView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height))
        aView.backgroundColor = UIColor.clear
        let cropLayer = CAShapeLayer()
        aView.layer.addSublayer(cropLayer)
        let path = CGMutablePath()
        
        let cropRect = CGRect(x: (aView.frame.width - self.scanViewHeight) * 0.5, y: (aView.frame.height - self.scanViewHeight) * 0.5, width: self.scanViewHeight, height: self.scanViewHeight)
        path.addRect(aView.bounds)
        path.addRect(cropRect)
        cropLayer.fillRule = kCAFillRuleEvenOdd
        cropLayer.path = path
        cropLayer.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor
        return aView
    }()
    
    fileprivate lazy var descLabel: UILabel = {
        let descLabel = UILabel(frame: CGRect.zero)
        descLabel.text = "将二维码放入框内，即可自动扫描"
        descLabel.font = UIFont.systemFont(ofSize: 12)
        descLabel.textColor = UIColor.white
        descLabel.sizeToFit()
        descLabel.center = self.view.center
        return descLabel
    }()
    
    fileprivate lazy var scanView: UIView = {
        let aView = UIView(frame: CGRect(x: 0, y: 0, width: self.scanViewHeight, height: self.scanViewHeight))
        aView.center = self.view.center
        
        let imageView1 = UIImageView(image:UIImage(named: "ScanQR1"))
        let imageView2 = UIImageView(image:UIImage(named: "ScanQR2"))
        let imageView3 = UIImageView(image:UIImage(named: "ScanQR3"))
        let imageView4 = UIImageView(image:UIImage(named: "ScanQR4"))
        
        imageView1.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
        imageView2.frame = CGRect(x: aView.frame.width - 16, y: 0, width: 16, height: 16)
        imageView3.frame = CGRect(x: 0, y: aView.frame.height - 16, width: 16, height: 16)
        imageView4.frame = CGRect(x: aView.frame.width - 16, y: aView.frame.height - 16, width: 16, height: 16)
        aView.addSubview(imageView1)
        aView.addSubview(imageView2)
        aView.addSubview(imageView3)
        aView.addSubview(imageView4)
        aView.addSubview(self.lineImage)
        aView.backgroundColor = UIColor.clear
        
        self.descLabel.frame.origin.y = aView.frame.maxY + 8
        self.view.addSubview(self.descLabel)
        return aView
    }()
    
    fileprivate lazy var lineImage: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.scanViewHeight, height: 15))
        imageView.image = UIImage(named: "QRCodeScanLine")
        return imageView
    }()
    
    /// MARK: - 点击事件
    fileprivate func dissmissVC() {
        if (navigationController != nil) {
            _ = navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    /// 初始化方法
    fileprivate func setupSubviews() {
        view.backgroundColor = UIColor.white
        view.addSubview(backgroundView)
        view.addSubview(scanView)
    }
    
    fileprivate func setupScaner() {
        scanner.scanFrame = scanView.frame
        scanner.autoRemoveSubLayers = true
    }
    
    @objc fileprivate func lineMoveAnimate() {
        if animating {
            UIView.animate(withDuration: 2.5, animations: {
                self.lineImage.frame.origin.y = self.scanView.frame.height - 16
            }, completion: { (finished) -> Void in
                self.lineImage.frame.origin.y = 0
                self.lineMoveAnimate()
            })
        }
    }
    
    /// MARK: - 生命周期方法
    override open func viewDidLoad() {
        super.viewDidLoad()
        title = "扫一扫"
        setupSubviews()
        setupScaner()
        lineMoveAnimate()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scanner.startScan()
        animating = true
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        scanner.stopScan()
        animating = false
    }
    
    deinit {
        debugPrint("deinit")
    }
}

extension XZQRCodeController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            weak var weakSC = self
            weakSC?.scanner.scanImage(image) {
                if ($0.count > 0) {
                    weakSC?.scanImageStringValue = $0.first
                    picker.dismiss(animated: false) {
                        if ((weakSC?.navigationController?.perform(#selector(weakSC?.navigationController?.popViewController(animated:)))) != nil) {
                            _ = weakSC?.navigationController?.popViewController(animated: true)
                        } else {
                            weakSC?.dismiss(animated: true, completion: nil)
                        }
                    }
                } else {
                    weakSC?.descLabel.text = "没有识别到二维码，请选择其他照片"
                    weakSC?.descLabel.sizeToFit()
                    picker.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}


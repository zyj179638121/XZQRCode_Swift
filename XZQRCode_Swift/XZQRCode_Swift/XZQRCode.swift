//
//  XZQRCode.swift
//  XZQRCode_Swift
//
//  Created by MYKJ on 17/1/6.
//  Copyright © 2017年 zhaoyongjie. All rights reserved.
//

import UIKit
import AVFoundation

class XZQRCode: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    
    /// corner line width
    var lineWidth: CGFloat
    /// corner stroke color
    var strokeColor: UIColor
    /// the max count for detection
    var maxDetectedCount: Int
    /// current count for detection
    var currentDetectedCount: Int = 0
    /// auto remove sub layers when detection completed
    var autoRemoveSubLayers: Bool
    /// completion call back
    var completedCallBack: ((_ stringValue: String) -> ())?
    /// the scan rect, default is the bounds of the scan view, can modify it if need
    var scanFrame: CGRect = CGRect.zero
    
    ///  init function
    ///
    ///  - returns: the scanner object
    override init() {
        self.lineWidth = 4
        self.strokeColor = UIColor.green
        self.maxDetectedCount = 20
        self.autoRemoveSubLayers = false
        
        super.init()
    }
    
    ///  init function
    ///
    ///  - parameter autoRemoveSubLayers: remove sub layers auto after detected code image
    ///  - parameter lineWidth:           line width, default is 4
    ///  - parameter strokeColor:         stroke color, default is Green
    ///  - parameter maxDetectedCount:    max detecte count, default is 20
    ///
    ///  - returns: the scanner object
    init(autoRemoveSubLayers: Bool, lineWidth: CGFloat = 4, strokeColor: UIColor = UIColor.green, maxDetectedCount: Int = 20) {
        
        self.lineWidth = lineWidth
        self.strokeColor = strokeColor
        self.maxDetectedCount = maxDetectedCount
        self.autoRemoveSubLayers = autoRemoveSubLayers
    }
    
    deinit {
        if session.isRunning {
            session.stopRunning()
        }
        
        removeAllLayers()
    }
    
    // MARK: - Generate QRCode Image
    ///  generate image
    ///
    ///  - parameter stringValue: string value to encoe
    ///  - parameter avatarImage: avatar image will display in the center of qrcode image
    ///  - parameter avatarScale: the scale for avatar image, default is 0.25
    ///
    ///  - returns: the generated image
    class func generateImage(_ stringValue: String, avatarImage: UIImage?, avatarScale: CGFloat = 0.25) -> UIImage? {
        return generateImage(stringValue, avatarImage: avatarImage, avatarScale: avatarScale, color: CIColor(color: UIColor.black), backColor: CIColor(color: UIColor.white))
    }
    
    ///  Generate Qrcode Image
    ///
    ///  - parameter stringValue: string value to encoe
    ///  - parameter avatarImage: avatar image will display in the center of qrcode image
    ///  - parameter avatarScale: the scale for avatar image, default is 0.25
    ///  - parameter color:       the CI color for forenground, default is black
    ///  - parameter backColor:   th CI color for background, default is white
    ///
    ///  - returns: the generated image
    class func generateImage(_ stringValue: String, avatarImage: UIImage?, avatarScale: CGFloat = 0.25, color: CIColor, backColor: CIColor) -> UIImage? {
        
        // generate qrcode image
        let qrFilter = CIFilter(name: "CIQRCodeGenerator")!
        qrFilter.setDefaults()
        qrFilter.setValue(stringValue.data(using: String.Encoding.utf8, allowLossyConversion: false), forKey: "inputMessage")
        
        let ciImage = qrFilter.outputImage
        
        // scale qrcode image
        let colorFilter = CIFilter(name: "CIFalseColor")!
        colorFilter.setDefaults()
        colorFilter.setValue(ciImage, forKey: "inputImage")
        colorFilter.setValue(color, forKey: "inputColor0")
        colorFilter.setValue(backColor, forKey: "inputColor1")
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let transformedImage = qrFilter.outputImage!.applying(transform)
        
        let image = UIImage(ciImage: transformedImage)
        
        if avatarImage != nil {
            return insertAvatarImage(image, avatarImage: avatarImage!, scale: avatarScale)
        }
        
        return image
    }
    
    class func insertAvatarImage(_ codeImage: UIImage, avatarImage: UIImage, scale: CGFloat) -> UIImage {
        
        let rect = CGRect(x: 0, y: 0, width: codeImage.size.width, height: codeImage.size.height)
        UIGraphicsBeginImageContext(rect.size)
        
        codeImage.draw(in: rect)
        
        let avatarSize = CGSize(width: rect.size.width * scale, height: rect.size.height * scale)
        let x = (rect.width - avatarSize.width) * 0.5
        let y = (rect.height - avatarSize.height) * 0.5
        avatarImage.draw(in: CGRect(x: x, y: y, width: avatarSize.width, height: avatarSize.height))
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return result!
    }
    
    // MARK: - Video Scan
    ///  prepare scan
    ///
    ///  - parameter view:       the scan view, the preview layer and the drawing layer will be insert into this view
    ///  - parameter completion: the completion call back
    func prepareScan(_ view: UIView, completion:@escaping (_ stringValue: String)->()) {
        
        scanFrame = view.bounds
        
        completedCallBack = completion
        currentDetectedCount = 0
        
        setupSession()
        setupLayers(view)
    }
    
    // MARK: - Image Scan
    ///  prepare scan
    ///
    ///  - parameter image:
    ///  - parameter completion: the completion call back
    func scanImage(_ image: UIImage, completion: @escaping ([String]) -> ()) {
        DispatchQueue.global(qos: .default).async {
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: CIContext(options: nil), options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
            
            let ciImage = CIImage(image: image)
            
            let features = detector?.features(in: ciImage!)
            
            var arrayM: [String] = []
            for feature in features as! [CIQRCodeFeature] {
                arrayM.append(feature.messageString ?? "")
            }
            
            DispatchQueue.main.async {
                completion(arrayM)
            }
        }
    }
    
    @discardableResult
    func openTorch() -> Bool {
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        if (device?.hasTorch)! {
            do {
                try device?.lockForConfiguration()
            } catch {
                debugPrint(error)
            }
            device?.torchMode = (device?.torchMode == .on) ? .off : .on
            device?.unlockForConfiguration()
        }
        return (device!.torchMode == .on) ? true : false
    }
    
    /// start scan
    func startScan() {
        if session.isRunning {
            debugPrint("====QRCodeScanner====")
            debugPrint("扫描器已运行")
            
            return
        }
        session.startRunning()
    }
    
    /// stop scan
    func stopScan() {
        if !session.isRunning {
            debugPrint("====QRCodeScanner====")
            debugPrint("扫描器已运行")
            
            return
        }
        session.stopRunning()
    }
    
    func setupLayers(_ view: UIView) {
        drawLayer.frame = view.bounds
        view.layer.insertSublayer(drawLayer, at: 0)
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
    }
    
    func setupSession() {
        if session.isRunning {
            debugPrint("====QRCodeScanner====")
            debugPrint("扫描器已运行")
            return
        }
        
        if !session.canAddInput(videoInput) {
            debugPrint("====QRCodeScanner====")
            debugPrint("找不到输入设备")
            return
        }
        
        if !session.canAddOutput(dataOutput) {
            debugPrint("====QRCodeScanner====")
            debugPrint("找不到输入设备")
            return
        }
        
        session.addInput(videoInput)
        session.addOutput(dataOutput)
        
        dataOutput.metadataObjectTypes = dataOutput.availableMetadataObjectTypes;
        dataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        clearDrawLayer()
        
        for dataObject in metadataObjects {
            
            if let codeObject = dataObject as? AVMetadataMachineReadableCodeObject,
                let obj = previewLayer.transformedMetadataObject(for: codeObject) as? AVMetadataMachineReadableCodeObject {
                
                if scanFrame.contains(obj.bounds) {
                    currentDetectedCount += 1
                    if currentDetectedCount > maxDetectedCount {
                        session.stopRunning()
                        
                        completedCallBack!(codeObject.stringValue ?? "")
                        
                        if autoRemoveSubLayers {
                            removeAllLayers()
                        }
                    }
                    
                    // transform codeObject
                    drawCodeCorners(previewLayer.transformedMetadataObject(for: codeObject) as! AVMetadataMachineReadableCodeObject)
                }
            }
        }
    }
    
    func removeAllLayers() {
        previewLayer.removeFromSuperlayer()
        drawLayer.removeFromSuperlayer()
    }
    
    func clearDrawLayer() {
        if drawLayer.sublayers == nil {
            return
        }
        
        for layer in drawLayer.sublayers! {
            layer.removeFromSuperlayer()
        }
    }
    
    func drawCodeCorners(_ codeObject: AVMetadataMachineReadableCodeObject) {
        if codeObject.corners.count == 0 {
            return
        }
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.lineWidth = lineWidth
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.path = createPath(codeObject.corners as NSArray).cgPath
        
        drawLayer.addSublayer(shapeLayer)
    }
    
    func createPath(_ points: NSArray) -> UIBezierPath {
        let path = UIBezierPath()
        var point = CGPoint()
        
        var index = 0
        CGPoint.__setFromDictionaryRepresentation(points[index] as! CFDictionary, &point)
        index += 1
        path.move(to: point)
        
        while index < points.count {
            CGPoint.__setFromDictionaryRepresentation(points[index] as! CFDictionary, &point)
            index += 1
            path.addLine(to: point)
        }
        path.close()
        
        return path
    }
    
    /// previewLayer
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        layer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        return layer!
    }()
    
    /// drawLayer
    lazy var drawLayer = CALayer()
    /// session
    lazy var session = AVCaptureSession()
    /// input
    lazy var videoInput: AVCaptureDeviceInput? = {
        
        if let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) {
            return try? AVCaptureDeviceInput(device: device)
        }
        return nil
    }()
    
    /// output
    lazy var dataOutput = AVCaptureMetadataOutput()
}

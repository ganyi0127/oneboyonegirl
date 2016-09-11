//
//  ViewController.swift
//  face
//
//  Created by ganyi on 16/9/8.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    //图片view
    @IBOutlet weak var boyImageView: UIImageView!
    @IBOutlet weak var girlImageView: UIImageView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var resultLabel: UILabel!
    
    private var currentImageTag:Int?
    
    //原图
    private var boyImage: UIImage?
    private var girlImage: UIImage?
    
    lazy var context: CIContext = {
        return CIContext(options: nil)
    }()
    
    //---------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        config()
        createContents()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        boyImageView.subviews.forEach(){
            view in
            view.removeFromSuperview()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    private func config(){
        
        startButton.layer.cornerRadius = startButton.frame.height / 2
        
        let strokeLayer = CAShapeLayer()
        strokeLayer.path = UIBezierPath(rect: boyImageView.bounds).CGPath
        strokeLayer.strokeColor = UIColor.lightGrayColor().CGColor
        strokeLayer.lineWidth = 10
        strokeLayer.fillColor = UIColor.clearColor().CGColor
        boyImageView.layer.addSublayer(strokeLayer)
        
        //添加头像点击事件
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapImage(_:)))
        boyImageView.addGestureRecognizer(tap)
        girlImageView.addGestureRecognizer(tap)
    }
    
    private func createContents(){
        
    }
    
    func tapImage(gesture: UIGestureRecognizer){
        
        guard currentImageTag == nil else{
            return
        }
        
        currentImageTag = gesture.view?.tag
        
        let alertController = UIAlertController(title: nil, message: "获取照片", preferredStyle: .ActionSheet)
        //取消按钮
        let cancelAction = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        //相册按钮
        let libraryAction = UIAlertAction(title: "相册", style: .Default){
            action in
            
            self.selectPhotoFromLibrary()
        }
        alertController.addAction(libraryAction)
        
        //相机按钮
        let cameraAction = UIAlertAction(title: "摄像头", style: .Default){
            action in
            
            self.selectPhotoFromCamera()
        }
        alertController.addAction(cameraAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    //MARK:识别图片
    @IBAction func start(sender: UIButton) {
        
        //清除之前的识别
        clearMark()
        
        guard let _boyImage = boyImage else{
            print("empty boyImage")
            return
        }
        
        guard let _girlImage = girlImage else{
            print("empty girlImage")
            return
        }
        
        guard let _boyInputImage = CIImage(image: _boyImage) else{
            print("boy inputImage error")
            return
        }
        
        guard let _girlInputImage = CIImage(image: _girlImage) else{
            print("girl inputImage error")
            return
        }
        
        recognise(withImage: _boyInputImage, formImageView: boyImageView)
        recognise(withImage: _girlInputImage, formImageView: girlImageView)
    }
    
    //MARK:检测
    private func recognise(withImage image:CIImage, formImageView imageView:UIImageView){
        
        //人脸检测器
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        
        var faceFeatures: [CIFaceFeature]!
        faceFeatures = detector.featuresInImage(image) as! [CIFaceFeature]
        
        print(faceFeatures)
        
        let inputImageSize = image.extent.size
        var transform = CGAffineTransformIdentity
        transform = CGAffineTransformScale(transform, 1, -1)
        transform = CGAffineTransformTranslate(transform, 0, -inputImageSize.height)
        
        //遍历所有的面部，并框出
        for faceFeature in faceFeatures {
            var faceViewBounds = CGRectApplyAffineTransform(faceFeature.bounds, transform)
            
            // 由于检测的原图放在imageView中缩放的原因,我们还要考虑缩放比例和x,y轴偏移
            let scale = min(boyImageView.bounds.size.width / inputImageSize.width,
                            boyImageView.bounds.size.height / inputImageSize.height)
            let offsetX = (boyImageView.bounds.size.width - inputImageSize.width * scale) / 2 * 0
            let offsetY = (boyImageView.bounds.size.height - inputImageSize.height * scale) / 2 * 0
            
            faceViewBounds = CGRectApplyAffineTransform(faceViewBounds, CGAffineTransformMakeScale(scale, scale))
            faceViewBounds.origin.x += offsetX
            faceViewBounds.origin.y += offsetY
            //faceFeature.
            //每个人脸对应一个UIView方框
            let faceView = UIView(frame: faceViewBounds)
            faceView.layer.borderColor = UIColor.orangeColor().CGColor
            faceView.layer.borderWidth = 2
            imageView.addSubview(faceView)
            
            let mouthBound = CGRect(origin: faceFeature.mouthPosition, size: CGSize(width: 4, height: 4))
            var mouthRect = CGRectApplyAffineTransform(mouthBound, transform)
            mouthRect = CGRectApplyAffineTransform(mouthRect, CGAffineTransformMakeScale(scale, scale))
            let mouth = UIView(frame: mouthRect)
            mouth.layer.borderColor = UIColor.orangeColor().CGColor
            mouth.layer.borderWidth = 2
            imageView.addSubview(mouth)
            
            let leftEyeBound = CGRect(origin: faceFeature.leftEyePosition, size: CGSize(width: 4, height: 4))
            var leftEyeRect = CGRectApplyAffineTransform(leftEyeBound, transform)
            leftEyeRect = CGRectApplyAffineTransform(leftEyeRect, CGAffineTransformMakeScale(scale, scale))
            let leftEye = UIView(frame: leftEyeRect)
            leftEye.layer.borderColor = UIColor.orangeColor().CGColor
            leftEye.layer.borderWidth = 2
            imageView.addSubview(leftEye)
            
            let rightEyeBound = CGRect(origin: faceFeature.rightEyePosition, size: CGSize(width: 4, height: 4))
            var rightEyeRect = CGRectApplyAffineTransform(rightEyeBound, transform)
            rightEyeRect = CGRectApplyAffineTransform(rightEyeRect, CGAffineTransformMakeScale(scale, scale))
            let rightEye = UIView(frame: rightEyeRect)
            rightEye.layer.borderColor = UIColor.orangeColor().CGColor
            rightEye.layer.borderWidth = 2
            imageView.addSubview(rightEye)
            
            print("\nfaceFeature:\(faceFeature):\(faceFeature.bounds)\nmouth:\(faceFeature.hasMouthPosition):\(faceFeature.mouthPosition)\nleftEye:\(faceFeature.hasLeftEyePosition):\(faceFeature.leftEyePosition)\nrightEye:\(faceFeature.hasRightEyePosition):\(faceFeature.rightEyePosition)")
            
            //以下为垃圾算法
            let leftEyePosition = faceFeature.leftEyePosition
            let rightEyePosition = faceFeature.rightEyePosition
            let mouthPosition = faceFeature.mouthPosition
            
            let eyesDistance = sqrt(pow(leftEyePosition.x - rightEyePosition.x, 2) + pow(leftEyePosition.y - rightEyePosition.y, 2))
            let mouthLeftDistance = sqrt(pow(leftEyePosition.x - mouthPosition.x, 2) + pow(leftEyePosition.y - mouthPosition.y, 2))
            let mouthRightDistance = sqrt(pow(mouthPosition.x - rightEyePosition.x, 2) + pow(mouthPosition.y - rightEyePosition.y, 2))
            let averageMouthDistance = (mouthLeftDistance + mouthRightDistance) / 2
            
            let ratio = eyesDistance / faceFeature.bounds.height
            
            let sex = averageMouthDistance > eyesDistance ? "女" : "男"
            
            print("\nratio:\(ratio)\nsex:\(sex)")
            let age = Int(ratio * 56)
            resultLabel.text = "\(ratio) 目测年龄:\(age)"
        }

    }
    
    //MARK:清楚标记
    private func clearMark(){
        
        boyImageView.subviews.forEach(){
            view in
            view.removeFromSuperview()
        }
        
        girlImageView.subviews.forEach(){
            view in
            view.removeFromSuperview()
        }
    }
    
    //MARK:从相机中拍摄照片
    private func selectPhotoFromCamera(){
        
        guard UIImagePickerController.isSourceTypeAvailable(.Camera) else{
            let alertController = UIAlertController(title: "选择照片", message: "获取相册图片失效", preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "我知道了", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            presentViewController(alertController, animated: true, completion: nil)
            return
        }
        
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = UIImagePickerControllerSourceType.Camera
        cameraPicker.modalPresentationStyle = .CurrentContext
        cameraPicker.allowsEditing = true
        cameraPicker.showsCameraControls = true
        cameraPicker.cameraDevice = .Rear
        presentViewController(cameraPicker, animated: true, completion: nil)
    }
    
    //MARK:从相册中获取图片
    private func selectPhotoFromLibrary(){
        
        guard UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) else{
            let alertController = UIAlertController(title: "选择照片", message: "获取图片失效", preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "我知道了", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            presentViewController(alertController, animated: true, completion: nil)
            return
        }
        
        let libraryPicker = UIImagePickerController()
        libraryPicker.delegate = self
        libraryPicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        libraryPicker.modalPresentationStyle = .CurrentContext
        libraryPicker.allowsEditing = true
        presentViewController(libraryPicker, animated: true, completion: nil)
    }
}

//MARK:照片库delegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        boyImage = image
        if let tag = currentImageTag{
            if tag == 0{
                boyImageView.layer.contents = image.CGImage
            }else{
                girlImageView.layer.contents = image.CGImage
            }
            currentImageTag = nil
        }
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
}
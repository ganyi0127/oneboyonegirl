//
//  ViewController.swift
//  face
//
//  Created by ganyi on 16/9/8.
//  Copyright © 2016年 ganyi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    //result_data
    struct Data {
        var ratio1:CGFloat?
        var ratio2:CGFloat?
    }
    
    //boy|girl_image_view
    @IBOutlet weak var boyImageView: UIImageView!
    @IBOutlet weak var girlImageView: UIImageView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var resultLabel: UILabel!
    
    //mark_tag_boy|girl
    fileprivate var currentImageTag:Int?
    
    //origin_uiimage
    fileprivate var boyImage: UIImage?
    fileprivate var girlImage: UIImage?
    
    //context
    lazy fileprivate let context: CIContext = {
        return CIContext(options: nil)
    }()
    
    //CIDetector_once
    lazy fileprivate let detector:CIDetector = {
        return CIDetector(ofType: CIDetectorTypeFace, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
    }
    
    //---------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        config()
        createContents()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        boyImageView.subviews.forEach(){
            view in
            view.removeFromSuperview()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    fileprivate func config(){
        
        startButton.layer.cornerRadius = startButton.frame.height / 2
        
        let strokeLayer = CAShapeLayer()
        strokeLayer.path = UIBezierPath(rect: boyImageView.bounds).cgPath
        strokeLayer.strokeColor = UIColor.lightGray.cgColor
        strokeLayer.lineWidth = 10
        strokeLayer.fillColor = UIColor.clear.cgColor
        boyImageView.layer.addSublayer(strokeLayer)
        
        //添加头像点击事件
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapImage(_:)))
        boyImageView.addGestureRecognizer(tap)
        girlImageView.addGestureRecognizer(tap)
    }
    
    fileprivate func createContents(){
        
    }
    
    func tapImage(_ gesture: UIGestureRecognizer){
        
        guard currentImageTag == nil else{
            return
        }
        
        currentImageTag = gesture.view?.tag
        
        let alertController = UIAlertController(title: nil, message: "获取照片", preferredStyle: .actionSheet)
        //取消按钮
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        //相册按钮
        let libraryAction = UIAlertAction(title: "相册", style: .default){
            action in
            
            self.selectPhotoFromLibrary()
        }
        alertController.addAction(libraryAction)
        
        //相机按钮
        let cameraAction = UIAlertAction(title: "摄像头", style: .default){
            action in
            
            self.selectPhotoFromCamera()
        }
        alertController.addAction(cameraAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    //MARK:pair_boy_girl
    @IBAction func start(_ sender: UIButton) {
        
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
        
        guard let boyData = recognise(withImage: _boyInputImage, formImageView: boyImageView), let girlData = recognise(withImage: _girlInputImage, formImageView: girlImageView) else {
            return
        }
        
        print("boyData:\(boyData)\ngirlData:\(girlData)")
    }
    
    //MARK:recognise_photo
    private func recognise(withImage image:CIImage, formImageView imageView:UIImageView) -> Data?{
        
        let faceFeatures = detector.features(in: image) as! [CIFaceFeature]

        print(faceFeatures)
        
        let inputImageSize = image.extent.size
        var transform = CGAffineTransform.identity
        transform = transform.scaledBy(x: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -inputImageSize.height)
        
        //遍历所有的面部
        faceFeatures.forEach(){
            faceFeature in

            var faceViewBounds = faceFeature.bounds.applying(transform)

            let scale = min(boyImageView.bounds.size.width / inputImageSize.width,
                            boyImageView.bounds.size.height / inputImageSize.height)
         
            faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale, y: scale))

            //每个人脸对应一个UIView方框
            let faceView = UIView(frame: faceViewBounds)
            faceView.layer.borderColor = UIColor.orange.cgColor
            faceView.layer.borderWidth = 2
            imageView.addSubview(faceView)
            
            //傻傻地计算
            let leftEyePosition = faceFeature.leftEyePosition
            let rightEyePosition = faceFeature.rightEyePosition
            let mouthPosition = faceFeature.mouthPosition
            
            let eyesDistance = sqrt(pow(leftEyePosition.x - rightEyePosition.x, 2) + pow(leftEyePosition.y - rightEyePosition.y, 2))
            let mouthLeftDistance = sqrt(pow(leftEyePosition.x - mouthPosition.x, 2) + pow(leftEyePosition.y - mouthPosition.y, 2))
            let mouthRightDistance = sqrt(pow(mouthPosition.x - rightEyePosition.x, 2) + pow(mouthPosition.y - rightEyePosition.y, 2))
            let averageMouthDistance = (mouthLeftDistance + mouthRightDistance) / 2
            
            var data = Data()
            data.ratio1 = eyesDistance / averageMouthDistance
            data.ratio2 = eyesDistance / faceViewBounds.width
            
            return data
        }
        return nil
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
        
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else{
            let alertController = UIAlertController(title: "选择照片", message: "获取相册图片失效", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "我知道了", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
            return
        }
        
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = UIImagePickerControllerSourceType.camera
        cameraPicker.modalPresentationStyle = .currentContext
        cameraPicker.allowsEditing = true
        cameraPicker.showsCameraControls = true
        cameraPicker.cameraDevice = .rear
        present(cameraPicker, animated: true, completion: nil)
    }
    
    //MARK:从相册中获取图片
    private func selectPhotoFromLibrary(){
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else{
            let alertController = UIAlertController(title: "选择照片", message: "获取图片失效", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "我知道了", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
            return
        }
        
        let libraryPicker = UIImagePickerController()
        libraryPicker.delegate = self
        libraryPicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        libraryPicker.modalPresentationStyle = .currentContext
        libraryPicker.allowsEditing = true
        present(libraryPicker, animated: true, completion: nil)
    }
}

//MARK:照片库delegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    fileprivate let myRate:Int = 1
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        
        if let tag = currentImageTag{
            if tag == 1{
                boyImage = info[UIImagePickerControllerEditedImage] as? UIImage
                boyImageView.layer.contents = boyImage?.cgImage
            }else{
                girlImage = info[UIImagePickerControllerEditedImage] as? UIImage
                girlImageView.layer.contents = girlImage?.cgImage
            }
            currentImageTag = nil
       
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

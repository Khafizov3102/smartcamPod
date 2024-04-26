//
//  ViewController.swift
//  SmartCamMasterApp
//
//  Created by Alexey Nikiforov on 16.04.2024.
//

import UIKit
import AVFoundation
import CoreMotion
import CropViewController

final class CameraViewController: UIViewController {

    private lazy var bottomBar = BottomBarView()
    private lazy var topBar = TopBarView()
    private var cameraService: CameraService
    private var manager = CMMotionManager()
    
    private var panImages = [UIImage]()
    
    private let horizonControlView: UIView = {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 1))
            view.backgroundColor = .white
            return view
        }()
    private let leftHorizonControlView: UIView = {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 1))
            view.backgroundColor = .white
            return view
        }()
    private let rightHorizonControlView: UIView = {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 1))
            view.backgroundColor = .white
            return view
        }()
        
    private let landscapeHorizonControlView: UIView = {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 120))
            view.backgroundColor = .white
            return view
        }()
    private let landscapeLeftHorizonControlView: UIView = {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 20))
            view.backgroundColor = .white
            return view
        }()
    private let landscapeRightHorizonControlView: UIView = {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 20))
            view.backgroundColor = .white
            return view
        }()
    
    private lazy var panPreview: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        imageView.alpha = 0.5
        imageView.isHidden = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private var isPanOn = false

    init(cameraService: CameraService) {
        self.cameraService = cameraService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        cameraService = CameraService()
        cameraService.delegate = self
        checkPermissions()
        setupPreviewLayer()
        setupUI()
        addHorizontalControl()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        horizonControlView.center = CGPoint(x: view.frame.size.width / 2 , y: view.frame.size.height / 2)
        leftHorizonControlView.center = CGPoint(x: view.frame.size.width / 2 - 70, y: view.frame.size.height / 2)
        rightHorizonControlView.center = CGPoint(x: view.frame.size.width / 2 + 70, y: view.frame.size.height / 2)
        
        landscapeHorizonControlView.center = CGPoint(x: view.frame.size.width / 2 , y: view.frame.size.height / 2)
        landscapeLeftHorizonControlView.center = CGPoint(x: view.frame.size.width / 2, y: view.frame.size.height / 2 - 70)
        landscapeRightHorizonControlView.center = CGPoint(x: view.frame.size.width / 2, y: view.frame.size.height / 2 + 70)
    }

// MARK: - UI

    private func setupUI() {
        setupZoomRecognizer()

        view.addSubview(topBar)
        view.addSubview(bottomBar)
        view.addSubview(panPreview)
        
        bottomBar.delegate = self
        topBar.delegate = self
        
        panPreview.frame.origin.x -= view.frame.width * 0.7

        NSLayoutConstraint.activate([
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.23),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.23),

            topBar.topAnchor.constraint(equalTo: view.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.14),
        ])
    }

    private func setupZoomRecognizer() {
        let zoomRecognizer = UIPinchGestureRecognizer()
        zoomRecognizer.addTarget(self, action: #selector(didPinch(_:)))
        view.addGestureRecognizer(zoomRecognizer)
    }

    private func setupPreviewLayer() {
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraService.captureSession) as AVCaptureVideoPreviewLayer

        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }

    
}

// MARK: - Bottom bar delegate
extension CameraViewController: BottomBarDelegate {

    func switchCamera() {
        cameraService.switchCameraInput()

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func takePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.flashMode = topBar.isTorchOn ? .on : .off
        cameraService.photoOutput.capturePhoto(with: photoSettings, delegate: cameraService)

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

extension CameraViewController {
    @objc private func didPinch(_ recognizer: UIPinchGestureRecognizer) {
        if recognizer.state == .changed {
            cameraService.setZoom(scale: recognizer.scale)
        }
    }
}

//MARK: TopBarDelegate
extension CameraViewController: TopBarDelegate {
    func changePanMode(isPanOn: Bool) {
        if isPanOn == true {
            panPreview.image = UIImage()
        }
        self.isPanOn = isPanOn
        panPreview.isHidden = !isPanOn
    }
}

// MARK: - Checking permision
extension CameraViewController {
    private func checkPermissions() {
        let cameraAuthStatus =  AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch cameraAuthStatus {
        case .authorized:
            return
        case .denied:
            abort()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
                                            { (authorized) in
                if(!authorized){
                    abort()
                }
            })
        case .restricted:
            abort()
        @unknown default:
            fatalError()
        }
    }
}

// MARK: horizontControl
private extension CameraViewController {
    func addHorizontalControl() {
        [
            horizonControlView,
            leftHorizonControlView,
            rightHorizonControlView,
            landscapeHorizonControlView,
            landscapeLeftHorizonControlView,
            landscapeRightHorizonControlView
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
        ])
        
        setupHorizontalControl()
    }
    
    func setupHorizontalControl() {
        manager.deviceMotionUpdateInterval = 0.1
        manager.startDeviceMotionUpdates(to: OperationQueue.main) { (data, error) in
            guard let attitude = data?.attitude else { return }
            let pitch = attitude.pitch * 180.0 / .pi
            let roll = attitude.roll * 180.0 / .pi
                        
            if abs(pitch) <= 45 {
                self.setupLandscape()
                
                if abs(pitch) <= 2 {
                    self.setupEvenHorizon(transform: CGAffineTransform(rotationAngle: CGFloat(-attitude.pitch)))
                } else {
                    self.setupUnevenHorizon(transform: CGAffineTransform(rotationAngle: CGFloat(-attitude.pitch)))
                }
            } else {
                self.setupPortrait()
                
                if abs(roll) <= 2 {
                    self.setupEvenHorizon(transform: CGAffineTransform(rotationAngle: CGFloat(-attitude.roll / 3)))
                } else {
                    self.setupUnevenHorizon(transform: CGAffineTransform(rotationAngle: CGFloat(-attitude.roll / 3)))
                }
            }
        }
    }
    
    func setupLandscape() {
        self.landscapeHorizonControlView.isHidden = false
        self.landscapeLeftHorizonControlView.isHidden = false
        self.landscapeRightHorizonControlView.isHidden = false
        self.horizonControlView.isHidden = true
        self.leftHorizonControlView.isHidden = true
        self.rightHorizonControlView.isHidden = true
    }
    
    func setupPortrait() {
        self.landscapeHorizonControlView.isHidden = true
        self.landscapeLeftHorizonControlView.isHidden = true
        self.landscapeRightHorizonControlView.isHidden = true
        self.horizonControlView.isHidden = false
        self.leftHorizonControlView.isHidden = false
        self.rightHorizonControlView.isHidden = false
    }
    
    func setupEvenHorizon(transform: CGAffineTransform) {
        UIView.animate(withDuration: 0.15) {
            self.horizonControlView.backgroundColor = UIColor.systemYellow
            self.leftHorizonControlView.backgroundColor = UIColor.systemYellow
            self.rightHorizonControlView.backgroundColor = UIColor.systemYellow
            self.landscapeHorizonControlView.backgroundColor = UIColor.systemYellow
            self.landscapeLeftHorizonControlView.backgroundColor = UIColor.systemYellow
            self.landscapeRightHorizonControlView.backgroundColor = UIColor.systemYellow
            self.horizonControlView.transform = .identity
            self.landscapeHorizonControlView.transform = .identity
        }
    }
    
    func setupUnevenHorizon(transform: CGAffineTransform) {
        UIView.animate(withDuration: 0.15) {
            self.horizonControlView.backgroundColor = UIColor.white
            self.leftHorizonControlView.backgroundColor = UIColor.white
            self.rightHorizonControlView.backgroundColor = UIColor.white
            self.landscapeHorizonControlView.backgroundColor = UIColor.white
            self.landscapeLeftHorizonControlView.backgroundColor = UIColor.white
            self.landscapeRightHorizonControlView.backgroundColor = UIColor.white
            self.horizonControlView.transform = transform
            self.landscapeHorizonControlView.transform = transform
            self.landscapeHorizonControlView.transform = transform
        }
    }
}


// MARK: - Camera service delegate
extension CameraViewController: CameraServiceDelegate, CropViewControllerDelegate {
    func detectBlur(isBlur: Bool) {
        if isBlur {
            showAlert(title: "imageIsBlurredAlertTitle".localized, message: "imageIsBlurredAlertMessage".localized)
        }
    }
    
    func checkBrightness(isDark: Bool) {
        if isDark {
            showAlert(title: "imageIsDarkAlertTitle".localized, message: "imageIsDarkAlertMessage".localized)
        }
    }
    
    func setPhoto(image: UIImage, isGoodQuality: Bool) {
        if isGoodQuality {
            if !isPanOn {
                let cropViewController = CropViewController(image: image)
                cropViewController.delegate = self
                
                if let presentedViewController = presentedViewController {
                    presentedViewController.dismiss(animated: true) { [weak self] in
                        self?.present(cropViewController, animated: true)
                    }
                } else {
                    present(cropViewController, animated: true)
                }
            } else {
                panPreview.isHidden = false
                panPreview.image = image
                panImages.append(image)
                if panImages.count == 4 {
                    Task {
                        do {
                            let image = try await stitched()
//                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                            let cropViewController = CropViewController(image: image)
                            cropViewController.delegate = self
                            
                            if let presentedViewController = presentedViewController {
                                presentedViewController.dismiss(animated: true) { [weak self] in
                                    self?.present(cropViewController, animated: true)
                                }
                            } else {
                                present(cropViewController, animated: true)
                            }
                            
                        } catch let error as NSError {
                            let alert = UIAlertController(title: "Stitching Error", message: error.localizedDescription, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self.show(alert, sender: nil)
                        }
                    }
                }
            }
        }
    }
    
    func stitched() async throws -> UIImage {
        let stitchedImage:UIImage = try CVWrapper.process(with: panImages)
        panImages.removeAll()
        return stitchedImage
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        dismiss(animated: true)
        bottomBar.setUpPhoto(image: image)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

private extension CameraViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        
        present(alert, animated: true)
    }
}

//MARK: Rotade Image func
private extension CameraViewController {
    func rotadeImage(image: UIImage, completion: @escaping (UIImage) -> Void) {
        var imageOrientation = UIImage.Orientation.right
        manager.deviceMotionUpdateInterval = 0.1
        manager.startDeviceMotionUpdates(to: OperationQueue.main) { (data, error) in
            guard let attitude = data?.attitude else { return }
            let pitch = attitude.pitch * 180.0 / .pi
            let roll = attitude.roll * 180.0 / .pi
            
            if abs(pitch) <= 40 && roll < -40 {
                imageOrientation = UIImage.Orientation.left
            } else if abs(pitch) <= 40 && roll > 40 {
                imageOrientation = UIImage.Orientation.down
            } else {
                imageOrientation = UIImage.Orientation.right
            }
            
            let rotatedImage = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: imageOrientation)
            completion(rotatedImage)
        }
    }
}

//
//  CameraService.swift
//  SmartCamMasterApp
//
//  Created by Денис Хафизов on 18.04.2024.
//

import UIKit
import AVFoundation

import AVKit
import MessageUI
import AVFoundation
import Metal
import MetalPerformanceShaders
import MetalKit
import CoreMotion

protocol CameraServiceDelegate: AnyObject {

    func setPhoto(image: UIImage, isGoodQuality: Bool)
    func checkBrightness(isDark: Bool)
    func detectBlur(isBlur: Bool)
}

final class CameraService: NSObject {
    private var captureDevice: AVCaptureDevice?
    private var backCamera: AVCaptureDevice?
    private var frontCamera: AVCaptureDevice?

    private var backInput: AVCaptureInput!
    private var frontInput: AVCaptureInput!
    private let cameraQueue = DispatchQueue(label: "com.shpeklord.CapturingModelQueue")

    private var startZoom: CGFloat = 2.0
    private let zoomLimit: CGFloat = 10.0

    private var backCameraOn = true
    static var isBrightnessOn = true
    static var isDetectBlurOn = true

    weak var delegate: CameraServiceDelegate?
    private var manager = CMMotionManager()

    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    
    var mtlDevice: MTLDevice!
    var mtlCommandQueue: MTLCommandQueue!
    
    let levelBright: Double = 40

    override init() {
        super.init()
        setupAndStartCaptureSession()
    }

    func setZoom(scale: CGFloat) {
        guard let zoomFactor = captureDevice?.videoZoomFactor else {
            return
        }
        var newScaleFactor: CGFloat = 0

        newScaleFactor = (scale < 1.0
        ? (zoomFactor - pow(zoomLimit, 1.0 - scale))
        : (zoomFactor + pow(zoomLimit, (scale - 1.0) / 2.0)))

        newScaleFactor = minMaxZoom(zoomFactor * scale)
        updateZoom(scale: newScaleFactor)
    }

    func switchCameraInput() {
        captureSession.beginConfiguration()
        if backCameraOn {
            captureSession.removeInput(backInput)
            captureSession.addInput(frontInput)
            captureDevice = frontCamera
            backCameraOn = false
        } else {
            captureSession.removeInput(frontInput)
            captureSession.addInput(backInput)
            captureDevice = backCamera
            backCameraOn = true
            updateZoom(scale: startZoom)
        }

        photoOutput.connections.first?.videoOrientation = .portrait
        photoOutput.connections.first?.isVideoMirrored = !backCameraOn
        captureSession.commitConfiguration()
    }

    private func currentDevice() -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes:
                                                                    [.builtInTripleCamera,.builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera],
                                                                mediaType: .video,
                                                                position: .back)
        guard let device = discoverySession.devices.first
        else {
            return nil
        }

        if device.deviceType == .builtInDualCamera || device.deviceType == .builtInWideAngleCamera {
            startZoom = 1.0
        }
        return device
    }

    private func setupAndStartCaptureSession() {
        cameraQueue.async { [weak self] in
            self?.captureSession.beginConfiguration()

            if let canSetSessionPreset = self?.captureSession.canSetSessionPreset(.photo), canSetSessionPreset {
                self?.captureSession.sessionPreset = .photo
            }
            self?.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true

            self?.setupInputs()
            self?.setupOutput()

            self?.captureSession.commitConfiguration()
            self?.captureSession.startRunning()
        }
    }

    private func setupInputs() {
        backCamera = currentDevice()
        frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)

        guard let backCamera = backCamera,
              let frontCamera = frontCamera
        else {
            return
        }

        do {
            backInput = try AVCaptureDeviceInput(device: backCamera)
            guard captureSession.canAddInput(backInput) else {
                return
            }

            frontInput = try AVCaptureDeviceInput(device: frontCamera)
            guard captureSession.canAddInput(frontInput) else {
                return
            }
        } catch {
            fatalError("could not connect camera")
        }

        captureDevice = backCamera

        captureSession.addInput(backInput)

        if backCamera.deviceType == .builtInDualWideCamera || backCamera.deviceType == .builtInTripleCamera {
            updateZoom(scale: startZoom)
        }
    }

    private func setupOutput() {
        guard captureSession.canAddOutput(photoOutput) else {
            return
        }

        photoOutput.maxPhotoQualityPrioritization = .balanced

        captureSession.addOutput(photoOutput)
    }

    private func minMaxZoom(_ factor: CGFloat) -> CGFloat { min(max(factor, 1.0), zoomLimit) }

    private func updateZoom(scale: CGFloat) {
        do {
            defer { captureDevice?.unlockForConfiguration() }
            try captureDevice?.lockForConfiguration()
            captureDevice?.videoZoomFactor = scale
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("Fail to capture photo: \(String(describing: error))")
            return
        }
        guard let imageData = photo.fileDataRepresentation() else { return }
        guard let image = UIImage(data: imageData) else { return }
        
        let deviceOrientation = UIDevice.current.orientation
        
        let imageOrientation: UIImage.Orientation
        switch deviceOrientation {
        case .portrait:
            imageOrientation = .right
        case .portraitUpsideDown:
            imageOrientation = .left
        case .landscapeLeft:
            imageOrientation = .up
        case .landscapeRight:
            imageOrientation = .down
        default:
            imageOrientation = .up
        }
        
        let isGoodQuality = checkImage(image: image)
        print("isGoodQuality: \(isGoodQuality)")
        let rotatedImage = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: imageOrientation)
        DispatchQueue.main.async {
            self.delegate?.setPhoto(image: rotatedImage, isGoodQuality: isGoodQuality)
        }
    }
}

private extension CameraService {
//    func rotadeImage(image: UIImage, completion: @escaping (UIImage) -> Void) {
//        var imageOrientation = UIImage.Orientation.right
//        manager.deviceMotionUpdateInterval = 0.1
//        manager.startDeviceMotionUpdates(to: OperationQueue.main) { (data, error) in
//            guard let attitude = data?.attitude else { return }
//            let pitch = attitude.pitch * 180.0 / .pi
//            let roll = attitude.roll * 180.0 / .pi
//            
//            if abs(pitch) <= 40 && roll < -40 {
//                imageOrientation = UIImage.Orientation.left
//            } else if abs(pitch) <= 40 && roll > 40 {
//                imageOrientation = UIImage.Orientation.down
//            } else {
//                imageOrientation = UIImage.Orientation.right
//            }
//            
//            let rotatedImage = UIImage(cgImage: image.cgImage!, scale: 1.0, orientation: imageOrientation)
//            completion(rotatedImage)
//        }
//    }
    
    func checkImage(image: UIImage) -> Bool {
        var isDark = false
        var isBlur = false
        if CameraService.isBrightnessOn {
            isDark = checkImageForBrightness(image: image)
        }
        delegate?.checkBrightness(isDark: isDark)
        
        if CameraService.isDetectBlurOn && !CameraService.isBrightnessOn {
            let cgImage = self.getCGlmage(from: image)
            if let cgImage = cgImage {
                if getVarianceOf(image: cgImage) <= 3 {
                    delegate?.detectBlur(isBlur: true)
                    isBlur = true
                }
            }
        }
        print("isDark: \(isDark) isBlur: \(isBlur)")
        
        if isDark || isBlur {
            return false
        } else {
            return true
        }
    }
    
    func checkImageForBrightness(image: UIImage) -> Bool {
        if CameraService.isBrightnessOn {
            let result = image.brightness < self.levelBright
            return result
        } else {
            return false
        }
    }
    
    func InitializeMTL(){
        self.mtlDevice = MTLCreateSystemDefaultDevice()
        self.mtlCommandQueue = mtlDevice?.makeCommandQueue()
    }
    
    func getSourceTextureFrom(image: CGImage) -> MTLTexture {
        let textureLoader = MTKTextureLoader(device: self.mtlDevice)
        let sourceTexture = try! textureLoader.newTexture(cgImage: image, options: nil)
        return sourceTexture
    }
    
    func textureFormatting(sourceTexture: MTLTexture) -> MTLTexture {
        let lapDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: sourceTexture.pixelFormat, width: sourceTexture.width, height: sourceTexture.height, mipmapped: false)
        lapDesc.usage = [.shaderWrite, .shaderRead]
        let lapTex = self.mtlDevice.makeTexture(descriptor: lapDesc)!
        return lapTex
    }
    
    func getTextureForStoringVariance(from sourceTexture: MTLTexture) -> MTLTexture {
        let varianceTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: sourceTexture.pixelFormat, width: 2, height: 1, mipmapped: false)
        varianceTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        let varianceTexture = self.mtlDevice.makeTexture(descriptor: varianceTextureDescriptor)!
        return varianceTexture
    }
    
    
     func getVarianceOf(image: CGImage) -> Int {
        InitializeMTL()
        
        let laplacian = MPSImageLaplacian(device: self.mtlDevice)
        let meanAndVariance = MPSImageStatisticsMeanAndVariance(device: self.mtlDevice)
        let sourceTexture = getSourceTextureFrom(image: image)
        let lapTex = textureFormatting(sourceTexture: sourceTexture)
        let commandBuffer = self.mtlCommandQueue.makeCommandBuffer()!
        let varianceTexture = getTextureForStoringVariance(from: sourceTexture)
        let region = MTLRegionMake2D(0, 0, 2, 1)
        var result = [Int8](repeatElement(0, count: 2))
        
        laplacian.encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: lapTex)
        meanAndVariance.encode(commandBuffer: commandBuffer, sourceTexture: lapTex, destinationTexture: varianceTexture)
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        varianceTexture.getBytes(&result, bytesPerRow: 1 * 2 * 4, from: region, mipmapLevel: 0)
        
        guard let result = result.last else { return 0 }
        return Int(result)
    }
    
    func getCGlmage(from image: UIImage) -> CGImage? {
        if let ciImage = CIImage(image: image){
            let context = CIContext(options: nil)
            return context.createCGImage(ciImage, from: ciImage.extent)
        }
        return nil
    }
}


//
//  TopBarView.swift
//  SmartCamMasterApp
//
//  Created by Денис Хафизов on 18.04.2024.
//

import UIKit

protocol TopBarDelegate: AnyObject {
    func changePanMode(isPanOn: Bool)
}

protocol TopBarSettingsDelegate: AnyObject {
    func changeBrightnessMode(isBrightnessOn: Bool)
    func changeDetectBlurMode(isDetectBlurOn: Bool)
}

final class TopBarView: UIView {
    
    weak var delegate: TopBarDelegate?
    weak var settingsDelegate: TopBarSettingsDelegate?

    lazy var flashButton: UIButton = {
        let button = UIButton()
        button.tintColor = .white
        button.backgroundColor = .clear
        button.setImage(UIImage(systemName: "bolt.circle", withConfiguration: UIImage.SymbolConfiguration.init(pointSize: 30)), for: .normal)
        button.imageView?.contentMode = .scaleToFill
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        return button
    }()

    lazy var brightnessButton: UIButton = {
        let button = UIButton()
        button.tintColor = .systemYellow
        button.backgroundColor = .clear
        button.setImage(UIImage(systemName: "sun.max", withConfiguration: UIImage.SymbolConfiguration.init(pointSize: 30)), for: .normal)
        button.imageView?.contentMode = .scaleToFill
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(toggleBrightness), for: .touchUpInside)
        return button
    }()
    
    lazy var detectBlurButton: UIButton = {
        let button = UIButton()
        button.tintColor = .systemYellow
        button.backgroundColor = .clear
        button.setImage(UIImage(systemName: "camera.aperture", withConfiguration: UIImage.SymbolConfiguration.init(pointSize: 30)), for: .normal)
        button.imageView?.contentMode = .scaleToFill
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(toggleDetectBlur), for: .touchUpInside)
        return button
    }()
    
    lazy var togglePanButton: UIButton = {
        let button = UIButton()
        button.tintColor = .white
        button.backgroundColor = .clear
        button.setImage(UIImage(systemName: "square.3.layers.3d.down.right", withConfiguration: UIImage.SymbolConfiguration.init(pointSize: 30)), for: .normal)
        button.imageView?.contentMode = .scaleToFill
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(togglePan), for: .touchUpInside)
        return button
    }()
    
    var isTorchOn = false {
        didSet {
            if isTorchOn {
                flashButton.tintColor = .systemYellow
            } else {
                flashButton.tintColor = .white
            }
        }
    }
    
    var isDetectBlurOn = true {
        didSet {
            if isDetectBlurOn {
                detectBlurButton.tintColor = .systemYellow
            } else {
                detectBlurButton.tintColor = .white
            }
        }
    }
    
    var isBrightnessOn = true {
        didSet {
            if isBrightnessOn {
                brightnessButton.tintColor = .systemYellow
            } else {
                brightnessButton.tintColor = .white
            }
        }
    }
    
    var isPanOn = false {
        didSet {
            if isPanOn {
                togglePanButton.tintColor = .systemYellow
            } else {
                togglePanButton.tintColor = .white
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)

        setUpUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpUI() {

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .black.withAlphaComponent(0.5)

        addSubview(flashButton)
        addSubview(brightnessButton)
        addSubview(detectBlurButton)
        addSubview(togglePanButton)
        
        NSLayoutConstraint.activate([
            flashButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            flashButton.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            flashButton.widthAnchor.constraint(equalToConstant: 35),
            flashButton.heightAnchor.constraint(equalToConstant: 35),
            
            brightnessButton.leadingAnchor.constraint(equalTo: flashButton.trailingAnchor, constant: 12),
            brightnessButton.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            brightnessButton.widthAnchor.constraint(equalToConstant: 35),
            brightnessButton.heightAnchor.constraint(equalToConstant: 35),
            
            detectBlurButton.leadingAnchor.constraint(equalTo: brightnessButton.trailingAnchor, constant: 12),
            detectBlurButton.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            detectBlurButton.widthAnchor.constraint(equalToConstant: 35),
            detectBlurButton.heightAnchor.constraint(equalToConstant: 35),
            
            togglePanButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            togglePanButton.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            togglePanButton.widthAnchor.constraint(equalToConstant: 35),
            togglePanButton.heightAnchor.constraint(equalToConstant: 35),
        ])
    }

    @objc private func toggleFlash() {
        isTorchOn.toggle()
    }
    
    @objc private func toggleBrightness() {
        isBrightnessOn.toggle()
        CameraService.isBrightnessOn = isBrightnessOn
    }
    
    @objc private func toggleDetectBlur() {
        isDetectBlurOn.toggle()
        CameraService.isDetectBlurOn = isDetectBlurOn
    }
    
    @objc private func togglePan() {
        isPanOn.toggle()
        delegate?.changePanMode(isPanOn: isPanOn)
    }
}

//
//  BottomBarView.swift
//  SmartCamMasterApp
//
//  Created by Денис Хафизов on 18.04.2024.
//

import UIKit

protocol BottomBarDelegate: AnyObject {
    
    func takePhoto()
}

final class BottomBarView: UIView {

    private lazy var captureImageButton = CaptureImageButton()

    private lazy var lastPhotoView = LastPhotoView()

    weak var delegate: BottomBarDelegate?

    override init(frame: CGRect) {
        super.init(frame: .zero)

        setUpUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpUI() {
        addSubview(captureImageButton)
        addSubview(lastPhotoView)

        backgroundColor = .black.withAlphaComponent(0.5)

        translatesAutoresizingMaskIntoConstraints = false

        captureImageButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        captureImageButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        lastPhotoView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        lastPhotoView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        lastPhotoView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        lastPhotoView.heightAnchor.constraint(equalToConstant: 50).isActive = true

        captureImageButton.addTarget(self, action: #selector(captureImage(_:)), for: .touchUpInside)
    }

    @objc private func captureImage(_ sender: UIButton?) {
        delegate?.takePhoto()
    }

    func setUpPhoto(image: UIImage) {
        lastPhotoView.imageView.image = image
    }
}


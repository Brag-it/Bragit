//
//  SignupImageUploadView.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import SnapKit
import Then
import UIKit

final class SignupImageUploadView: UIView {
  private let headerView = UIView()
  let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }
  private let headerLabel = UILabel().then {
    $0.text = "회원가입"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
  }

  // MARK: UI 컴포넌트 정의

  private let descriptionTitleLabel = UILabel().then {
    $0.text = "나를 잘 나나태는 사진을 올려 볼까요?"
    $0.numberOfLines = 1
    $0.lineBreakMode = .byWordWrapping
    $0.setContentHuggingPriority(.required, for: .vertical)
    $0.setContentCompressionResistancePriority(.required, for: .vertical)
    $0.font = .pretendard(size: 20, weight: .semibold)
    $0.textColor = .grayScale900
  }

  let imageButton = UIButton(type: .system).then {
    $0.setTitle(nil, for: .normal)
    $0.backgroundColor = UIColor.grayScale100
    $0.clipsToBounds = true
    $0.imageView?.contentMode = .center
    $0.tintColor = .grayScale600
    let placeholder = UIImage.mypage
      .resized(to: CGSize(width: 60, height: 60))
      .withRenderingMode(.alwaysTemplate)
    $0.setImage(placeholder, for: .normal)
  }

  let cameraButton = UIButton(type: .system).then {
    $0.setTitle(nil, for: .normal)
    $0.backgroundColor = .black
    $0.layer.cornerRadius = 24
    $0.layer.masksToBounds = true
    $0.layer.borderWidth = 1
    $0.layer.borderColor = UIColor.separator.cgColor
    $0.isUserInteractionEnabled = false
    $0.isAccessibilityElement = false

    let icon = UIImage.camera
      .resized(to: CGSize(width: 24, height: 24))
      .withRenderingMode(.alwaysTemplate)
    $0.setImage(icon, for: .normal)
    $0.tintColor = .white
    $0.imageView?.contentMode = .scaleAspectFill
  }

  let imagePicker = UIImagePickerController().then {
    $0.allowsEditing = true
  }

  lazy var beLaterButton = UIButton().then {
    $0.setTitle("나중에", for: .normal)
    $0.setTitleColor(.grayScale700, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16, weight: .regular)
  }

  lazy var nextButton = UIButton().then {
    $0.setTitle("다음", for: .normal)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16, weight: .medium)
    $0.layer.cornerRadius = 12
    $0.backgroundColor = .primary400
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    headerUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func headerUI() {
    addSubview(headerView)
    [backButton, headerLabel].forEach { headerView.addSubview($0) }

    headerView.snp.makeConstraints {
      $0.top.equalTo(safeAreaLayoutGuide.snp.top)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(58)
    }

    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(20)
      $0.centerY.equalTo(headerView.snp.centerY)
    }

    headerLabel.snp.makeConstraints {
      $0.centerX.equalTo(headerView.snp.centerX)
      $0.centerY.equalTo(headerView.snp.centerY)
      $0.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(20)
    }

    configureUI()
  }

  private func configureUI() {
    [descriptionTitleLabel, imageButton, cameraButton, beLaterButton, nextButton].forEach { addSubview($0) }

    descriptionTitleLabel.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    imageButton.snp.makeConstraints {
      $0.top.equalTo(descriptionTitleLabel.snp.bottom).offset(32)
      $0.centerX.equalToSuperview()
      $0.width.height.equalTo(150)
    }

    cameraButton.snp.makeConstraints {
      $0.width.height.equalTo(48)
      $0.trailing.equalTo(imageButton.snp.trailing)
      $0.bottom.equalTo(imageButton.snp.bottom)
    }

    beLaterButton.snp.makeConstraints {
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.bottom.equalTo(nextButton.snp.top).offset(-8)
      $0.height.equalTo(52)
    }

    nextButton.snp.makeConstraints {
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.bottom.equalTo(safeAreaLayoutGuide).inset(24)
      $0.height.equalTo(52)
    }
    bringSubviewToFront(cameraButton)
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    let diameter = min(imageButton.bounds.width, imageButton.bounds.height)
    imageButton.layer.cornerRadius = diameter / 2
    imageButton.layer.cornerCurve = .continuous
    imageButton.layer.masksToBounds = true

    imageButton.configuration = nil
  }

  // 외부에서 선택된 이미지를 전달하여 버튼 이미지를 갱신합니다.
  func setSelectedImage(_ image: UIImage?) {
    if let image = image {
      imageButton.setImage(nil, for: .normal)
      imageButton.setBackgroundImage(image, for: .normal)
      imageButton.imageView?.contentMode = .scaleAspectFill
      imageButton.clipsToBounds = true
    } else {
      imageButton.setBackgroundImage(nil, for: .normal)
      let placeholder = UIImage.mypage
        .resized(to: CGSize(width: 60, height: 60))
        .withRenderingMode(.alwaysTemplate)
      imageButton.setImage(placeholder, for: .normal)
      imageButton.tintColor = .grayScale600
      imageButton.imageView?.contentMode = .center
    }
  }
}


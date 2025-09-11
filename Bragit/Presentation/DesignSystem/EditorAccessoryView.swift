//
//  EditorAccessoryView.swift
//  Bragit
//
//  Created by 이태윤 on 8/27/27.
//
import UIKit

import SnapKit
import Then
import RxSwift
import RxCocoa

final class EditorAccessoryView: UIView {
  // 볼드체 적용 버튼
  let boldButton = UIButton(type: .system).then {
    $0.setImage(UIImage(systemName: "bold"), for: .normal)
    $0.tintColor = .grayScaleBack
  }

  // 밑줄 적용 버튼
  let underlineButton = UIButton(type: .system).then {
    $0.setImage(UIImage(systemName: "underline"), for: .normal)
    $0.tintColor = .grayScaleBack
  }

  // 취소선 적용 버튼
  let strikethroughButton = UIButton(type: .system).then {
    $0.setImage(UIImage(systemName: "strikethrough"), for: .normal)
    $0.tintColor = .grayScaleBack
  }

  // 이미지 삽입 버튼
  let imageButton = UIButton(type: .system).then {
    $0.setImage(UIImage(systemName: "photo"), for: .normal)
    $0.tintColor = .grayScaleBack
  }

  // 키보드 내리는 버튼
  let keyboardDismissButton = UIButton(type: .system).then {
    $0.setImage(UIImage(systemName: "keyboard.chevron.compact.down"), for: .normal)
    $0.tintColor = .grayScaleBack
  }

  // 버튼 수평 스택 뷰
  private let stackView = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 16
    $0.distribution = .fillEqually
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
    setupLayout()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupView() {
    backgroundColor = .systemGray5
    layer.borderColor = UIColor.systemGray3.cgColor
    layer.borderWidth = 1.0

    [boldButton, underlineButton, strikethroughButton, imageButton].forEach {
      stackView.addArrangedSubview($0)
    }
  }

  private func setupLayout() {
    addSubview(stackView)
    addSubview(keyboardDismissButton)

    stackView.snp.makeConstraints {
      $0.top.bottom.equalToSuperview().inset(8)
      $0.leading.equalToSuperview().offset(16)
      $0.trailing.lessThanOrEqualTo(keyboardDismissButton.snp.leading).offset(-16)
    }

    keyboardDismissButton.snp.makeConstraints {
      $0.top.bottom.equalToSuperview().inset(8)
      $0.trailing.lessThanOrEqualToSuperview().offset(-16)
    }

    self.snp.makeConstraints {
      $0.height.equalTo(44)
    }
  }
}

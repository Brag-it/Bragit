//
//  HeaderView.swift
//  Bragit
//
//  Created by 이태윤 on 9/1/25.
//
import UIKit
import SnapKit

final class HeaderView: UICollectionReusableView {
  static let identifier = "HeaderView"


  private let titleLabel = UILabel().then {
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale600
  }

  private let pulsButton = UIButton(type: .system).then {
    $0.setImage(.plus, for: .normal)
    $0.tintColor = .grayScale600
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(titleLabel)
    titleLabel.snp.makeConstraints {
      $0.leading.equalToSuperview().inset(20)
      $0.top.bottom.equalToSuperview()
    }

    pulsButton.snp.makeConstraints {
      $0.trailing.equalToSuperview().inset(20)
      $0.top.bottom.equalToSuperview()
    }

  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(section: Section) {
    switch section {
    case .title:
      titleLabel.text = ""
      pulsButton.isHidden = true
    case .thumbnails:
      titleLabel.text = "대표 이미지(썸네일)"
      pulsButton.isHidden = true
    case .description:
      titleLabel.text = "게시글 설명"
      pulsButton.isHidden = true
    case .tags:
      titleLabel.text = "태그추가"
      pulsButton.isHidden = false
    }
  }
}


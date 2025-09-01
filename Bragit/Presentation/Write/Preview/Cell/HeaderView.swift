//
//  HeaderView.swift
//  Bragit
//
//  Created by 이태윤 on 9/1/25.
//
import UIKit

import SnapKit
import Then
import RxSwift

final class HeaderView: UICollectionReusableView {
  static let identifier = "HeaderView"
  var disposeBag = DisposeBag()

  private let titleLabel = UILabel().then {
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale600
  }

  let plusButton = UIButton(type: .system).then {
    $0.setImage(.plus, for: .normal)
    $0.contentMode = .scaleAspectFit
    $0.tintColor = .grayScale600
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(titleLabel)
    addSubview(plusButton)
    titleLabel.snp.makeConstraints {
      $0.leading.equalToSuperview()
      $0.top.bottom.equalToSuperview()
    }

    plusButton.snp.makeConstraints {
      $0.trailing.equalToSuperview()
      $0.top.bottom.equalToSuperview()
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
  }

  func configure(section: Section) {
    switch section {
    case .title:
      titleLabel.text = ""
      plusButton.isHidden = true
    case .thumbnails:
      titleLabel.text = "대표 이미지(썸네일)"
      plusButton.isHidden = true
    case .description:
      titleLabel.text = "게시글 설명"
      plusButton.isHidden = true
    case .tags:
      titleLabel.text = "태그추가"
      plusButton.isHidden = false
    }
  }
}

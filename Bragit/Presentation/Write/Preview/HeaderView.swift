//
//  HeaderView.swift
//  Bragit
//
//  Created by 이태윤 on 8/31/25.
//
import UIKit

import SnapKit

final class HeaderView: UICollectionReusableView {
  static let identifier = "HeaderView"

  let titleLabel = UILabel().then {
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale600
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(titleLabel)
    titleLabel.snp.makeConstraints {
      $0.leading.trailing.equalToSuperview().inset(16)
      $0.top.bottom.equalToSuperview()
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(title: String) {
    titleLabel.text = title
  }
}

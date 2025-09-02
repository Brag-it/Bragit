//
//  TitleCell.swift
//  Bragit
//
//  Created by 이태윤 on 9/1/25.
//
import UIKit

import SnapKit
import Then

final class TitleCell: UICollectionViewCell {
  static let identifier: String = "TitleCell"

  private let titleLabel = UILabel().then {
    $0.font = .pretendard(size: 20, weight: .semibold)
    $0.textColor = .grayScale700
  }

  private let dividerView = UIView().then {
    $0.backgroundColor = .grayScale100
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .white
    contentView.addSubview(titleLabel)
    contentView.addSubview(dividerView)

    titleLabel.snp.makeConstraints {
      $0.top.equalToSuperview()
      $0.leading.trailing.equalToSuperview()
    }

    dividerView.snp.makeConstraints {
      $0.top.equalTo(titleLabel.snp.bottom).offset(16)
      $0.leading.trailing.equalTo(titleLabel)
      $0.height.equalTo(1)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(text: String) {
    titleLabel.text = text
  }
}

//
//  EmptyCell.swift
//  Bragit
//
//  Created by 이태윤 on 9/8/25.
//
import UIKit

import SnapKit
import Then

final class EmptyCell: UICollectionViewCell {
  static let identifier: String = "EmptyCell"

  private let emptyImage = UIImageView().then {
    $0.image = .emptySearch
  }

  private let emptyLabel = UILabel().then {
    $0.text = "검색 결과가 없어요"
    $0.font = .pretendard(size: 16, weight: .medium)
    $0.textColor = .grayScale600
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .white
    contentView.addSubview(emptyImage)
    contentView.addSubview(emptyLabel)

    emptyImage.snp.makeConstraints {
      $0.center.equalToSuperview()
    }

    emptyLabel.snp.makeConstraints {
      $0.top.equalTo(emptyImage.snp.bottom).offset(16)
      $0.centerX.equalTo(emptyImage)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(message: String) {
    emptyLabel.text = message
  }
}

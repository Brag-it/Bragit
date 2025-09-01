//
//  TagCell.swift
//  Bragit
//
//  Created by 이태윤 on 9/1/25.
//
//
import UIKit

import SnapKit
import Then
final class TagCell: UICollectionViewCell {
  static let identifier: String = "TagCell"

  private let tagView = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 10
    $0.alignment = .center
    $0.distribution = .fill
  }

  private let tagLabel = UILabel().then {
    $0.font = .pretendard(size: 15, weight: .medium)
    $0.textColor = .grayScale700
  }

  private let xMarker = UIImageView().then {
    $0.image = .xMarker
    $0.contentMode = .scaleAspectFit
    $0.tintColor = .grayScale700
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .white
    contentView.layer.cornerRadius = 21
    contentView.layer.borderWidth = 1
    contentView.layer.borderColor = UIColor.grayScale100.cgColor
    contentView.addSubview(tagView)
    tagView.addArrangedSubview(tagLabel)
    tagView.addArrangedSubview(xMarker)

    tagView.snp.makeConstraints {
      $0.top.bottom.equalToSuperview()
      $0.leading.trailing.equalToSuperview().inset(14)
    }

    xMarker.snp.makeConstraints {
      $0.width.equalTo(16)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(text: String) {
    tagLabel.text = text
  }
}

//
//  ThumbnailCell.swift
//  Bragit
//
//  Created by 이태윤 on 8/31/25.
//
import UIKit

import SnapKit
import Then

final class ThumbnailCell: UICollectionViewCell {
  static let identifier: String = "ThumbnailCell"
  override var isSelected: BooleanLiteralType {
    didSet {
      contentView.layer.borderColor = isSelected ? UIColor.grayScaleBack.cgColor : UIColor.clear.cgColor
      checkIamge.isHidden = !isSelected // 선택 해제 및 선택
    }
  }
  private let imageView = UIImageView().then {
    $0.contentMode = .scaleAspectFill
    $0.clipsToBounds = true
  }

  private let checkIamge = UIImageView().then {
    $0.image = .check
    $0.tintColor = .grayScaleBack
    $0.isHidden = true
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.backgroundColor = .grayScale100
    contentView.layer.cornerRadius = 14
    contentView.layer.borderWidth = 3
    contentView.layer.borderColor = UIColor.clear.cgColor
    contentView.layer.masksToBounds = true
    contentView.addSubview(imageView)
    contentView.addSubview(checkIamge)
    imageView.snp.makeConstraints { $0.directionalEdges.equalToSuperview() }
    checkIamge.snp.makeConstraints { $0.top.trailing.equalTo(imageView).inset(8) }
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(image: UIImage) {
    imageView.image = image
  }
}

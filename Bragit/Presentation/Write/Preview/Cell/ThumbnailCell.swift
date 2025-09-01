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

  private let imageView = UIImageView().then {
    $0.contentMode = .scaleAspectFill
    $0.clipsToBounds = true
  }
  // 셀 초기화 시 UI 요소 등록 및 제약조건 설정
  override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.backgroundColor = .grayScale100
    contentView.layer.cornerRadius = 14
    contentView.layer.masksToBounds = true
    contentView.addSubview(imageView)
    imageView.snp.makeConstraints { $0.directionalEdges.equalToSuperview() }
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(image: UIImage) {
    imageView.image = image
  }
}

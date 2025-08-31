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


  // 셀 초기화 시 UI 요소 등록 및 제약조건 설정
  override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.backgroundColor = .grayScale100
    contentView.layer.cornerRadius = 14
    contentView.layer.masksToBounds = false

    setUIConstraints()
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  // UI 설정
  private func setUIConstraints() {

  }
}

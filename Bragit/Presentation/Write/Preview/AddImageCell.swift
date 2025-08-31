//
//  AddImageCell.swift
//  Bragit
//
//  Created by 이태윤 on 8/31/25.
//
import UIKit

import SnapKit
import Then
final class AddImageCell: UICollectionViewCell {
  static let identifier: String = "AddImageCell"

  private let plusImageView = UIImageView().then {
    $0.image = .camera
    $0.tintColor = .grayScale700
    $0.contentMode = .center
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.layer.cornerRadius = 14
    contentView.addSubview(plusImageView)
    plusImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

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
    contentView.backgroundColor = .grayScale100
    contentView.layer.cornerRadius = 14
    contentView.layer.masksToBounds = true
    contentView.addSubview(plusImageView)
    plusImageView.snp.makeConstraints { $0.directionalEdges.equalToSuperview() }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

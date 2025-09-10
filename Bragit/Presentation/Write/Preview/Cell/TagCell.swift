//
//  TagCell.swift
//  Bragit
//
//  Created by 이태윤 on 9/1/25.
//
import UIKit

import SnapKit
import Then
import RxSwift

final class TagCell: UICollectionViewCell {
  static let identifier: String = "TagCell"
  var disposeBag = DisposeBag()

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

  let xMarker = UIButton(type: .system).then {
    $0.setImage(.xMarker, for: .normal)
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
      $0.width.height.equalTo(16)
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(text: String) {
    tagLabel.text = text
  }
}

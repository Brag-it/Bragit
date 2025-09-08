//
//  RecentCell.swift
//  Bragit
//
//  Created by 이태윤 on 9/8/25.
//
import UIKit

import SnapKit
import Then
import RxSwift

final class RecentCell: UICollectionViewCell {
  static let identifier: String = "RecentCell"
  var disposeBag = DisposeBag()

  private let recentView = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 8
    $0.alignment = .center
    $0.distribution = .fill
  }

  private let recentLabel = UILabel().then {
    $0.font = .pretendard(size: 15, weight: .medium)
    $0.textColor = .grayScale900
  }

  let xMarker = UIButton(type: .system).then {
    $0.setImage(.xMarker, for: .normal)
    $0.contentMode = .scaleAspectFit
    $0.tintColor = .grayScale900
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .white
    contentView.addSubview(recentView)
    recentView.addArrangedSubview(recentLabel)
    recentView.addArrangedSubview(xMarker)

    recentView.snp.makeConstraints {
      $0.top.bottom.equalToSuperview()
      $0.leading.trailing.equalToSuperview().inset(20)
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
    recentLabel.text = text
  }
}

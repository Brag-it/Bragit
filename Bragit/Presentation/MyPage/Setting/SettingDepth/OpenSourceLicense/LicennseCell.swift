//
//  LicenseCell.swift
//  Bragit
//
//  Created by 이태윤 on 9/10/25.
//
import UIKit

import SnapKit
import Then
import RxSwift

final class LicenseCell: UICollectionViewCell {
  static let identifier: String = "LicenseCell"
  var disposeBag = DisposeBag()

  private let licenseView = UIView()

  private let licenseLabel = UILabel().then {
    $0.font = .pretendard(size: 15, weight: .medium)
    $0.textColor = .grayScale900
  }

  private let licenseSubLabel = UILabel().then {
    $0.font = .pretendard(size: 14)
    $0.textColor = .grayScale600
  }

  let nextButton = UIButton(type: .system).then {
    $0.setImage(.forward, for: .normal)
    $0.contentMode = .scaleAspectFit
    $0.tintColor = .grayScale900
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .white
    contentView.addSubview(licenseView)
    licenseView.addSubview(licenseLabel)
    licenseView.addSubview(licenseSubLabel)
    licenseView.addSubview(nextButton)

    licenseView.snp.makeConstraints {
      $0.top.bottom.equalToSuperview().inset(12)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    licenseLabel.snp.makeConstraints {
      $0.top.leading.equalToSuperview()
    }

    licenseSubLabel.snp.makeConstraints {
      $0.top.equalTo(licenseLabel.snp.bottom)
      $0.leading.equalToSuperview()
    }

    nextButton.snp.makeConstraints {
      $0.centerY.equalTo(licenseView.snp.centerY)
      $0.trailing.equalToSuperview()
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

  func configure(main: String, sub: String) {
    licenseLabel.text = main
    licenseSubLabel.text = sub
  }
}

//
//  SettingTermsCell.swift
//  Bragit
//
//  Created by 이태윤 on 9/10/25.
//
import UIKit

import SnapKit
import Then
import RxSwift

final class SettingTermsCell: UICollectionViewCell {
  static let identifier: String = "SettingTermsCell"
  var disposeBag = DisposeBag()

  private let termsView = UIView()

  private let termsLabel = UILabel().then {
    $0.font = .pretendard(size: 15, weight: .medium)
    $0.textColor = .grayScale900
  }

  let nextButton = UIButton(type: .system).then {
    $0.setImage(.forward, for: .normal)
    $0.contentMode = .scaleAspectFit
    $0.tintColor = .grayScale900
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .white
    contentView.addSubview(termsView)
    termsView.addSubview(termsLabel)
    termsView.addSubview(nextButton)

    termsView.snp.makeConstraints {
      $0.top.bottom.equalToSuperview().inset(12)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    termsLabel.snp.makeConstraints {
      $0.leading.equalToSuperview()
      $0.centerY.equalTo(termsView)
    }

    nextButton.snp.makeConstraints {
      $0.centerY.equalTo(termsView)
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

  func configure(text: String) {
    termsLabel.text = text
  }
}

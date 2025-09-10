//
//  UserInfoView.swift
//  Bragit
//
//  Created by seongjun cho on 9/1/25.
//

import UIKit

import SnapKit
import Then

class UserInfoView: UIView {

  private let numberLabel = UILabel().then {
    $0.font = .pretendard(size: 16, weight: .semibold)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
  }

  private let infoLabel = UILabel().then {
    $0.font = .pretendard(size: 14, weight: .regular)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
  }

  init (number: String, info: String) {
    super.init(frame: .zero)
    setupUI()
    numberLabel.text = number
    infoLabel.text = info
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    addSubview(numberLabel)
    addSubview(infoLabel)

    numberLabel.snp.makeConstraints {
      $0.top.equalToSuperview().offset(14)
      $0.leading.trailing.equalToSuperview()
    }

    infoLabel.snp.makeConstraints {
      $0.top.equalTo(numberLabel.snp.bottom).offset(2)
      $0.leading.trailing.equalToSuperview()
    }
  }

  func configure(number: String, info: String) {
    numberLabel.text = number
    infoLabel.text = info
  }

  func setNumber(number: String) {
    numberLabel.text = number
  }
}

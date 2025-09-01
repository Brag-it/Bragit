//
//  HeaderView.swift
//  Bragit
//
//  Created by 이태윤 on 9/1/25.
//
import UIKit
import SnapKit

final class HeaderView: UICollectionReusableView {
  static let identifier = "HeaderView"

  private let titleLabel = UILabel().then {
    $0.font = .boldSystemFont(ofSize: 28)
    $0.textColor = .label
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(titleLabel)
    titleLabel.snp.makeConstraints {
      $0.leading.trailing.equalToSuperview().inset(16)
      $0.top.bottom.equalToSuperview()
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(title: String) {
    titleLabel.text = title
  }
}


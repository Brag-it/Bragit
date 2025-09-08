//
//  UserCell.swift
//  Bragit
//
//  Created by 이태윤 on 9/8/25.
//
import UIKit

import SnapKit
import Then
import Kingfisher

final class UserCell: UICollectionViewCell {
  static let identifier: String = "UserCell"

  private let profileImageView = UIImageView().then {
    $0.layer.cornerRadius = 12
    $0.layer.masksToBounds = true
  }

  private let userLabel = UILabel().then {
    $0.font = .pretendard(size: 16, weight: .medium)
    $0.textColor = .grayScale900
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .white
    contentView.addSubview(profileImageView)
    contentView.addSubview(userLabel)

    profileImageView.snp.makeConstraints {
      $0.leading.equalToSuperview().inset(20)
      $0.top.equalToSuperview().inset(10)
      $0.bottom.equalToSuperview().inset(10)
      $0.width.height.equalTo(24)
    }

    userLabel.snp.makeConstraints {
      $0.top.equalTo(profileImageView)
      $0.leading.equalTo(profileImageView.snp.trailing).offset(12)
      $0.trailing.equalToSuperview().inset(20)
      $0.bottom.equalTo(profileImageView)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(user: User) {
    profileImageView.kf
      .setImage(with: URL(string: user.profile ?? ""), placeholder: UIImage.profilePerson)
    userLabel.text = user.nickname
  }
}

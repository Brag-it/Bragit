//
//  MyPageProfileCell.swift
//  Bragit
//
//  Created by seongjun cho on 9/1/25.
//

import UIKit

import SnapKit
import Then

final class MyPageProfileCell: UICollectionViewCell {

  static let identifier = "MyPageProfileCell"

  private let profileImageView = UIImageView().then {
    $0.contentMode = .scaleAspectFill
    $0.layer.cornerRadius = 24
    $0.clipsToBounds = true
  }

  private let editNickNameButton = UIButton().then {
    var configuration = UIButton.Configuration.plain()

    configuration.title = "닉네임"
    configuration.image = UIImage.pencil
    configuration.imagePlacement = .trailing
    configuration.imagePadding = 4

    $0.configuration = configuration
  }

  private let followerView = UserInfoView()

  private let followingView = UserInfoView()

  private let favoriteTagsView = UserInfoView()

  override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.addSubview(profileImageView)
    contentView.addSubview(editNickNameButton)

    profileImageView.snp.makeConstraints {
      $0.top.leading.equalToSuperview().offset(20)
      $0.height.width.equalTo(48)
    }

    editNickNameButton.snp.makeConstraints {
      $0.centerY.equalTo(profileImageView)
      $0.leading.equalTo(profileImageView.snp.trailing).offset(16)
    }

    fo
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure() {
  }
}

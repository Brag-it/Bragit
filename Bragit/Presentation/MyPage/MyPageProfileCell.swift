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
    $0.image = .profilePerson
  }

  private let editNickNameButton = UIButton().then {
    var configuration = UIButton.Configuration.plain()

    configuration.title = ""
    configuration.image = UIImage.pencil
    configuration.imagePlacement = .trailing
    configuration.imagePadding = 4
    configuration.baseForegroundColor = .black
    configuration.contentInsets = .zero

    $0.configuration = configuration
  }

  private let followerView = UserInfoView(number: "0", info: "팔로워")

  private let followingView = UserInfoView(number: "0", info: "팔로잉")

  private let favoriteTagsView = UserInfoView(number: "0", info: "관심 태그")

  private let stackView = UIStackView().then {
    $0.axis = .horizontal
    $0.distribution = .fillEqually
  }

  private let dividerView = UIView().then {
    $0.backgroundColor = .grayScale50
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.addSubview(profileImageView)
    contentView.addSubview(editNickNameButton)
    contentView.addSubview(stackView)
    contentView.addSubview(dividerView)

    stackView.addArrangedSubview(followerView)
    stackView.addArrangedSubview(followingView)
    stackView.addArrangedSubview(favoriteTagsView)

    profileImageView.snp.makeConstraints {
      $0.top.leading.equalToSuperview().offset(20)
      $0.height.width.equalTo(48)
    }

    editNickNameButton.snp.makeConstraints {
      $0.centerY.equalTo(profileImageView)
      $0.leading.equalTo(profileImageView.snp.trailing).offset(16)
    }

    stackView.snp.makeConstraints {
      $0.top.equalTo(profileImageView.snp.bottom).offset(14)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.bottom.equalTo(dividerView.snp.top)
    }

    dividerView.snp.makeConstraints {
      $0.bottom.leading.trailing.equalToSuperview()
      $0.height.equalTo(10)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(profile: Profile) {
    editNickNameButton.setTitle(profile.nickName, for: .normal)
    followerView.setNumber(number: String(profile.follwerCount))
    followingView.setNumber(number: String(profile.followingCount))
    favoriteTagsView.setNumber(number: String(profile.favoriteTagCount))
    profileImageView.kf.setImage(with: URL(string: profile.profileImage), placeholder: UIImage.profilePerson)
  }
}

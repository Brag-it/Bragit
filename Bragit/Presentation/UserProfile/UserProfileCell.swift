//
//  UserProfileCell.swift
//  Bragit
//
//  Created by seongjun cho on 9/9/25.
//

import UIKit

import SnapKit
import Then
import RxSwift

final class UserProfileCell: UICollectionViewCell {

  static let identifier = "MyPageProfileCell"

  var disposeBag = DisposeBag()

  private let profileImageView = UIImageView().then {
    $0.contentMode = .scaleAspectFill
    $0.layer.cornerRadius = 24
    $0.clipsToBounds = true
    $0.image = .profilePerson
    $0.isUserInteractionEnabled = true
  }

  private let nickNameLabel = UILabel().then {
    $0.font = .pretendard(size: 18, weight: .semibold)
  }

  let followButton = UIButton().then {
    var config = UIButton.Configuration.filled()
    config.attributedTitle?.font = .pretendard(size: 14, weight: .medium)
    config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
    config.baseForegroundColor = .grayScale900
    config.title = "팔로우"

    $0.setContentHuggingPriority(.required, for: .horizontal)
    $0.configuration = config
    $0.configurationUpdateHandler = { button in
      switch button.state {
      case .selected:
        button.configuration?.baseBackgroundColor = .grayScale100
        button.configuration?.title = "팔로잉"
      default:
        button.configuration?.baseBackgroundColor = .primary100
        button.configuration?.title = "팔로우"
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
      }
    }
  }

  private let followerView = UserInfoView(number: "0", info: "팔로워")
  private let followingView = UserInfoView(number: "0", info: "팔로잉")

  private let stackView = UIStackView().then {
    $0.axis = .horizontal
    $0.distribution = .fillEqually
  }

  private let dividerView = UIView().then {
    $0.backgroundColor = .grayScale50
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    setUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    self.disposeBag = DisposeBag()
  }

  private func setUI() {
    contentView.addSubview(profileImageView)
    contentView.addSubview(nickNameLabel)
    contentView.addSubview(stackView)
    contentView.addSubview(dividerView)
    contentView.addSubview(followButton)
    stackView.addArrangedSubview(followerView)
    stackView.addArrangedSubview(followingView)

    profileImageView.snp.makeConstraints {
      $0.top.leading.equalToSuperview().offset(20)
      $0.height.width.equalTo(48)
    }

    nickNameLabel.snp.makeConstraints {
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

    followButton.snp.makeConstraints {
      $0.centerY.equalTo(profileImageView)
      $0.trailing.equalToSuperview().inset(20)
    }
  }

  func configure(profile: Profile) {
    nickNameLabel.text = profile.nickName
    followerView.setNumber(number: String(profile.follwerCount))
    followingView.setNumber(number: String(profile.followingCount))
    profileImageView.kf.setImage(with: URL(string: profile.profileImage), placeholder: UIImage.profilePerson)

    if profile.isFollowing {
      followButton.isSelected = true
    } else {
      followButton.isSelected = false
    }
  }
}

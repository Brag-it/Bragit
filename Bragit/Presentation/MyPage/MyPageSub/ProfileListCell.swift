//
//  ProfileListCell.swift
//  Bragit
//
//  Created by seongjun cho on 9/3/25.
//

import UIKit

import SnapKit
import Then
import Kingfisher
import RxRelay
import RxSwift

final class ProfileListCell: UICollectionViewCell {

  private let imageView = UIImageView().then {
    $0.layer.cornerRadius = 20
    $0.layer.masksToBounds = true
  }

  private let textLabel = UILabel().then {
    $0.font = .pretendard(size: 15, weight: .medium)
    $0.numberOfLines = 1
  }

  private let followButton = UIButton().then {
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

  let followDidTap = PublishRelay<any Hashable>()
  private var disposeBag = DisposeBag()
  private var data: (any Hashable)?

  override init(frame: CGRect) {
    super.init(frame: frame)

    setUI()
    followButton.rx.tap.bind {
      [weak self] in
      guard let self = self, self.data != nil else { return }
      self.followDidTap.accept(self.data!)
      followButton.isSelected.toggle()
    }.disposed(by: disposeBag)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
  }

  func configure(data: any Hashable) {
    switch data {
    case let user as User:
      imageView.kf.setImage(with: URL(string: user.profile ?? ""), placeholder: UIImage.profilePerson)
      textLabel.text = user.nickname
      @LocalStorage(location: .followUser) var followUsers: [String]?
      if followUsers == nil {
        followUsers = []
      }
      if followUsers!.contains(where: { $0 == user.id }) {
        followButton.isSelected = true
      } else {
        followButton.isSelected = false
      }
      self.data = user
    case let tag as Tag:
      imageView.image = .union
      imageView.layer.cornerRadius = 0
      imageView.snp.updateConstraints {
        $0.width.height.equalTo(16.5)
      }
      textLabel.text = tag.tag
      @LocalStorage(location: .favoriteTags) var favoriteTags: [Tag]?
      if favoriteTags == nil {
        favoriteTags = []
      }
      if favoriteTags!.contains(tag) {
        followButton.isSelected = true
      } else {
        followButton.isSelected = false
      }
      self.data = tag
    default:
      imageView.image = .init()
      textLabel.text = ""
    }
  }

  private func setUI() {
    contentView.addSubview(imageView)
    contentView.addSubview(textLabel)
    contentView.addSubview(followButton)

    imageView.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(16)
      $0.centerY.equalToSuperview()
      $0.width.height.equalTo(40)
    }

    textLabel.snp.makeConstraints {
      $0.leading.equalTo(imageView.snp.trailing).offset(12)
      $0.centerY.equalToSuperview()
      $0.trailing.lessThanOrEqualTo(followButton.snp.leading).offset(-12)
    }

    followButton.snp.makeConstraints {
      $0.trailing.equalToSuperview().offset(-16)
      $0.centerY.equalToSuperview()
    }
  }
}

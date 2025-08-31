//
//  PostCell.swift
//  Bragit
//
//  Created by seongjun cho on 8/22/25.
//

import UIKit

import SnapKit
import Then
import Kingfisher
import RxRelay
import RxSwift

final class PostCell: UICollectionViewCell {

  private let profileImageView = UIImageView().then {
    $0.layer.cornerRadius = 18
    $0.layer.masksToBounds = true
  }

  private let userNameLabel = UILabel().then {
    $0.font = .pretendard(size: 15, weight: .medium)
    $0.text = "닉네임"
    $0.numberOfLines = 1
  }

  private let dateLabel = UILabel().then {
    $0.font = .pretendard(size: 13)
    $0.textColor = .systemGray
    $0.textAlignment = .right
    $0.text = "2분전"
  }

  private let thumbnailImageView = UIImageView().then {
    $0.layer.cornerRadius = 14
    $0.layer.masksToBounds = true
    $0.contentMode = .scaleAspectFill
  }
  private let titleLabel = UILabel().then {
    $0.font = .pretendard(size: 16, weight: .semibold)
    $0.text = "제목"
    $0.numberOfLines = 2
  }

  private let descriptionLabel = UILabel().then {
    $0.font = .pretendard(size: 14)
    $0.text = "미리보기글"
    $0.numberOfLines = 3
  }

  private let postStackView = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 10
  }

  private let tagsView = TagsView()

  private let bottomView = UIView()

  private let commentLabel = UILabel().then {
    $0.font = .pretendard(size: 14, weight: .medium)
    $0.textColor = .systemGray
    $0.text = "0"
  }

  private let commentImageView = UIImageView().then {
    $0.image = .comment.withRenderingMode(.alwaysTemplate)
    $0.tintColor = .systemGray
  }

  private let favoriteLabel = UILabel().then {
    $0.font = .pretendard(size: 14, weight: .medium)
    $0.textColor = .systemGray
    $0.text = "0"
  }

  private let favoriteImageView = UIImageView().then {
    $0.image = .favorite.withRenderingMode(.alwaysTemplate)
    $0.tintColor = .systemGray
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

  let followDidTap = PublishRelay<Post>()
  var reusableDisposeBag = DisposeBag()
  private let permanentDisposeBag = DisposeBag()
  private var post: Post?

  override init(frame: CGRect) {
    super.init(frame: frame)

    setUI()
    followButton.rx.tap.bind {
      [weak self] in
      guard let self = self, self.post != nil else { return }
      self.followDidTap.accept(self.post!)
      followButton.isSelected.toggle()
    }.disposed(by: permanentDisposeBag)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    tagsView.clearTags()
    reusableDisposeBag = DisposeBag()
  }

  func configure(data: Post) {
    self.post = data
    userNameLabel.text = data.author?.nickname
    profileImageView.kf
      .setImage(with: URL(string: data.author?.profile ?? ""), placeholder: UIImage.profilePerson)

    titleLabel.text = data.title
    descriptionLabel.text = data.description

    if data.thumbnailImage == nil {
      thumbnailImageView.isHidden = true
    } else {
      thumbnailImageView.isHidden = false
      thumbnailImageView.kf.setImage(with: URL(string: data.thumbnailImage ?? ""))
    }

    tagsView.configure(with: data.tags)

    commentLabel.text = "\(data.commentCount)"
    favoriteLabel.text = "\(data.like)"
    dateLabel.text = data.date.timeAgoDisplay()

    @LocalStorage(location: .followUser) var favoriteUsers: [String]?
    @LocalStorage(location: .nowUser) var myId: String?

    if data.author == nil || data.author?.id == myId ?? "" {
      followButton.isHidden = true
    } else {
      followButton.isHidden = false
    }

    if favoriteUsers != nil && favoriteUsers!.contains(data.author!.id) {
      followButton.isSelected = true
    } else {
      followButton.isSelected = false
    }
  }

  private func setUI() {
    contentView.addSubview(profileImageView)
    contentView.addSubview(userNameLabel)
    contentView.addSubview(postStackView)
    contentView.addSubview(followButton)
    postStackView.addArrangedSubview(thumbnailImageView)
    postStackView.addArrangedSubview(titleLabel)
    postStackView.addArrangedSubview(descriptionLabel)
    postStackView.addArrangedSubview(tagsView)
    postStackView.addArrangedSubview(bottomView)
    bottomView.addSubview(commentLabel)
    bottomView.addSubview(commentImageView)
    bottomView.addSubview(favoriteLabel)
    bottomView.addSubview(favoriteImageView)
    bottomView.addSubview(dateLabel)

    profileImageView.snp.makeConstraints {
      $0.top.equalToSuperview().offset(16)
      $0.leading.equalToSuperview().offset(20)
      $0.height.width.equalTo(36)
    }

    userNameLabel.snp.makeConstraints {
      $0.leading.equalTo(profileImageView.snp.trailing).offset(12)
      $0.centerY.equalTo(profileImageView)
      $0.trailing.equalTo(followButton.snp.leading).inset(12)
    }

    followButton.snp.makeConstraints {
      $0.centerY.equalTo(profileImageView)
      $0.trailing.equalToSuperview().inset(20)
    }

    thumbnailImageView.snp.makeConstraints {
      $0.height.equalTo(thumbnailImageView.snp.width).multipliedBy(0.713).priority(999)
    }

    postStackView.snp.makeConstraints {
      $0.top.equalTo(profileImageView.snp.bottom).offset(10)
      $0.leading.trailing.bottom.equalToSuperview().inset(20)
    }

    commentLabel.snp.makeConstraints {
      $0.top.bottom.equalToSuperview()
      $0.trailing.equalToSuperview()
    }

    commentImageView.snp.makeConstraints {
      $0.top.bottom.equalToSuperview()
      $0.trailing.equalTo(commentLabel.snp.leading).offset(-2)
    }

    favoriteLabel.snp.makeConstraints {
      $0.top.bottom.equalToSuperview()
      $0.trailing.equalTo(commentImageView.snp.leading).offset(-10)
    }

    favoriteImageView.snp.makeConstraints {
      $0.top.bottom.equalToSuperview()
      $0.trailing.equalTo(favoriteLabel.snp.leading).offset(-2)
    }

    tagsView.snp.makeConstraints {
      $0.height.lessThanOrEqualTo(75)
    }

    dateLabel.snp.makeConstraints {
      $0.top.leading.bottom.equalToSuperview()
    }
  }
}

//
//  FavoriteSectionHeaderView.swift
//  Bragit
//
//  Created by seongjun cho on 8/28/25.
//

import UIKit

import RxSwift
import RxRelay
import SnapKit
import Then
import Kingfisher

final class FavoriteSectionHeaderView: UICollectionReusableView {

  static let identifier = "FavoriteSectionHeaderView"

  let tagDidTap = PublishRelay<Tag?>()
  let followingUserDidTap = PublishRelay<User>()
  var disposeBag = DisposeBag()
  var postType = FavoriteReactor.PostType.emptyUser

  private let mainStackView = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 10
  }

  private let titleContainerView = UIView()

  private let titleLabel = UILabel().then {
    $0.font = .pretendard(size: 14)
    $0.textColor = .grayScale400
    $0.isHidden = true
  }

  private let scrollView = UIScrollView().then {
    $0.showsHorizontalScrollIndicator = false
    $0.showsVerticalScrollIndicator = false
    $0.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    $0.isHidden = true
  }

  private let tagStackView = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 8
    $0.isHidden = true
  }

  private let divderView = UIView().then {
    $0.backgroundColor = .grayScale50
  }

  private let followStackView = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 8
    $0.isHidden = true
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    self.backgroundColor = .white
    addSubview(mainStackView)
    addSubview(divderView)

    titleContainerView.addSubview(titleLabel)
    mainStackView.addArrangedSubview(titleContainerView)
    mainStackView.addArrangedSubview(scrollView)
    scrollView.addSubview(tagStackView)
    scrollView.addSubview(followStackView)

    mainStackView.snp.makeConstraints {
      $0.top.bottom.equalToSuperview().inset(14)
      $0.leading.trailing.equalToSuperview()
    }

    scrollView.snp.makeConstraints {
      $0.height.equalTo(42).priority(999)
    }

    tagStackView.snp.makeConstraints {
      $0.centerY.equalTo(scrollView.frameLayoutGuide)
      $0.leading.trailing.equalTo(scrollView.contentLayoutGuide)
    }

    followStackView.snp.makeConstraints {
      $0.centerY.equalTo(scrollView.frameLayoutGuide)
      $0.leading.trailing.equalTo(scrollView.contentLayoutGuide)
    }

    divderView.snp.makeConstraints {
      $0.leading.trailing.bottom.equalToSuperview()
      $0.height.equalTo(1)
    }

    titleLabel.snp.makeConstraints {
      $0.top.bottom.equalToSuperview()
      $0.leading.trailing.equalToSuperview().inset(20)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
    scrollView.isHidden = true
    titleContainerView.isHidden = true
    titleLabel.isHidden = true
    followStackView.isHidden = true
    tagStackView.isHidden = true
    tagStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    followStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
  }

  func configure(postType: FavoriteReactor.PostType, selectedTag: Tag?) {
    self.postType = postType

    switch postType {
    case .emptyTag(let tags):
      titleContainerView.isHidden = false
      titleLabel.isHidden = false
      titleLabel.text = "추천 태그"
      scrollView.isHidden = false
      tagStackView.isHidden = false
      makeTags(tags: tags, selectedTag: selectedTag)
    case .tag(let tags):
      scrollView.isHidden = false
      tagStackView.isHidden = false
      scrollView.snp.updateConstraints {
        $0.height.equalTo(42).priority(999)
      }
      makeTags(tags: tags, selectedTag: selectedTag)
    case .emptyUser:
      titleContainerView.isHidden = false
      titleLabel.isHidden = false
      titleLabel.text = "추천 사용자"
    case .user(let users):
      scrollView.isHidden = false
      followStackView.isHidden = false
      scrollView.snp.updateConstraints {
        $0.height.equalTo(82).priority(999)
      }
      makeFollowList(users: users.sorted {
        $0.latestUploaded ?? Date() < $1.latestUploaded ?? Date()
      })
    }
  }

  private func makeTags(tags: [Tag], selectedTag: Tag?) {
    tagStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

    for tag in tags {
      let tagButton = UIButton()
      var config = UIButton.Configuration.filled()
      config.title = tag.tag
      config.attributedTitle?.font = .pretendard(size: 15, weight: .medium)
      config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
      config.cornerStyle = .capsule
      tagButton.configuration = config
      tagButton.setContentHuggingPriority(.required, for: .horizontal)
      tagButton.setContentCompressionResistancePriority(.required, for: .horizontal)

      tagButton.configurationUpdateHandler = { button in
        switch button.state {
        case .selected:
          button.configuration?.baseForegroundColor = .white
          button.configuration?.baseBackgroundColor = .grayScale900
          button.configuration?.background.strokeWidth = 0
        default:
          button.configuration?.baseForegroundColor = .grayScale600
          button.configuration?.baseBackgroundColor = .white
          button.configuration?.background.strokeColor = .grayScale100
          button.configuration?.background.strokeWidth = 1.0
        }
      }

      tagButton.snp.makeConstraints {
        $0.height.equalTo(42)
      }

      tagButton.rx.tap
        .bind { [tagStackView, tagDidTap] in
          // 선택된 버튼을 또 누른경우
          if tagButton.isSelected {
            tagButton.isSelected = false
            tagDidTap.accept(nil)
          } else {
            // 전부 false로 바꿈
            tagStackView.arrangedSubviews.forEach { view in
              if let button = view as? UIButton {
                button.isSelected = false
              }
            }

            tagButton.isSelected = true
            tagDidTap.accept(tag)
          }
        }
        .disposed(by: disposeBag)

      if tag.id == selectedTag?.id {
        tagButton.isSelected = true
      }
      tagStackView.addArrangedSubview(tagButton)
    }
  }

  private func makeFollowList(users: [User]) {
    followStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    for user in users {
      let profileStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 6
      }

      let nameLabel = UILabel().then {
        $0.text = user.nickname
        $0.font = .pretendard(size: 12, weight: .medium)
        $0.textColor = .grayScale700
        $0.textAlignment = .center
        $0.numberOfLines = 1
      }

      let profileButton = UIButton().then {
        $0.kf.setImage(with: URL(string: user.profile ?? ""), for: .normal, placeholder: UIImage.profilePerson)
        $0.frame.size = CGSize(width: 60, height: 60)
        $0.layer.cornerRadius = 30
        $0.layer.masksToBounds = true
        $0.contentMode = .scaleAspectFill
      }

      profileButton.rx.tap
        .bind { [followingUserDidTap] in
          followingUserDidTap.accept(user)
        }
        .disposed(by: disposeBag)

      profileStackView.addArrangedSubview(profileButton)
      profileStackView.addArrangedSubview(nameLabel)
      profileStackView.snp.makeConstraints {
        $0.width.equalTo(60)
        $0.height.equalTo(nameLabel.font.lineHeight + 60 + 6)
      }

      followStackView.addArrangedSubview(profileStackView)
    }
  }
}

//
//  BlockListCell.swift
//  Bragit
//
//  Created by seongjun cho on 9/18/25.
//

import UIKit

import SnapKit
import Then
import Kingfisher
import RxRelay
import RxSwift

final class BlockListCell: UICollectionViewCell {

  private let imageView = UIImageView().then {
    $0.layer.cornerRadius = 20
    $0.layer.masksToBounds = true
  }

  private let textLabel = UILabel().then {
    $0.font = .pretendard(size: 15, weight: .medium)
    $0.numberOfLines = 1
  }

  private let blockButton = UIButton().then {
    var config = UIButton.Configuration.filled()
    config.attributedTitle?.font = .pretendard(size: 14, weight: .medium)
    config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
    config.baseForegroundColor = .grayScale900
    config.title = "차단해제"

    $0.setContentHuggingPriority(.required, for: .horizontal)
    $0.configuration = config
    $0.isSelected = true
    $0.configurationUpdateHandler = { button in
      switch button.state {
      case .selected:
        button.configuration?.baseBackgroundColor = .grayScale100
        button.configuration?.title = "차단해제"
      default:
        button.configuration?.baseBackgroundColor = .primary100
        button.configuration?.title = "차단하기"
      }
      button.layer.cornerRadius = 12
      button.layer.masksToBounds = true
    }
  }

  let blockDidTap = PublishRelay<User>()
  var disposeBag = DisposeBag()
  private var user: User?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
  }

  func configure(user: User) {
    imageView.kf.setImage(with: URL(string: user.profile ?? ""), placeholder: UIImage.profilePerson)
    textLabel.text = user.nickname
    @LocalStorage(location: .blockUser) var blockUsers: [String]?
    if blockUsers == nil {
      blockUsers = []
    }
    if blockUsers!.contains(where: { $0 == user.id }) {
      blockButton.isSelected = true
    } else {
      blockButton.isSelected = false
    }
    self.user = user

    blockButton.rx.tap.bind { [blockDidTap, blockButton] in
      blockDidTap.accept(user)
      blockButton.isSelected.toggle()
    }.disposed(by: disposeBag)
  }

  private func setUI() {
    contentView.addSubview(imageView)
    contentView.addSubview(textLabel)
    contentView.addSubview(blockButton)

    imageView.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(16)
      $0.centerY.equalToSuperview()
      $0.width.height.equalTo(40)
    }

    textLabel.snp.makeConstraints {
      $0.leading.equalTo(imageView.snp.trailing).offset(12)
      $0.centerY.equalToSuperview()
      $0.trailing.lessThanOrEqualTo(blockButton.snp.leading).offset(-12)
    }

    blockButton.snp.makeConstraints {
      $0.trailing.equalToSuperview().offset(-16)
      $0.centerY.equalToSuperview()
    }
  }
}

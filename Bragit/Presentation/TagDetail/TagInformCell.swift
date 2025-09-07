//
//  TagInformCell.swift
//  Bragit
//
//  Created by seongjun cho on 9/4/25.
//

import UIKit

import Then
import SnapKit
import RxSwift

final class TagInformCell: UICollectionViewCell {

  static let identifier = "TagInformCell"

  var disposeBag = DisposeBag()

  private let tagLabel = UILabel().then {
    $0.font = .pretendard(size: 28, weight: .semibold)
    $0.textColor = .black
    $0.numberOfLines = 1
  }

  let followButton = UIButton().then {
    let image = UIImage.favorite.withRenderingMode(.alwaysOriginal)
    let selectedImage = UIImage.favoriteFilled.withRenderingMode(.alwaysOriginal)

    $0.setImage(image.withTintColor(.grayScale600), for: .normal)
    $0.setImage(selectedImage.withTintColor(.systemDanger), for: .selected)
  }

  private let tagHasPostLabel = UILabel().then {
    $0.font = .pretendard(size: 14)
    $0.textColor = .grayScale600
    $0.text = "이 태그가 포함된 게시글"
    $0.numberOfLines = 1
  }

  private let postCountLabel = UILabel().then {
    $0.font = .pretendard(size: 14, weight: .medium)
    $0.textColor = .grayScale600
    $0.numberOfLines = 1
    $0.textAlignment = .right
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
    contentView.addSubview(tagLabel)
    contentView.addSubview(followButton)
    contentView.addSubview(tagHasPostLabel)
    contentView.addSubview(postCountLabel)
    contentView.addSubview(dividerView)

    tagLabel.snp.makeConstraints {
      $0.top.equalToSuperview().offset(24)
      $0.leading.equalToSuperview().offset(20)
      $0.trailing.equalToSuperview().inset(10)
    }

    followButton.snp.makeConstraints {
      $0.top.equalToSuperview().offset(24)
      $0.trailing.equalToSuperview().inset(20)
      $0.width.height.equalTo(32)
    }

    tagHasPostLabel.snp.makeConstraints {
      $0.top.equalTo(tagLabel.snp.bottom).offset(16)
      $0.leading.equalToSuperview().offset(20)
      $0.trailing.equalTo(postCountLabel.snp.leading).inset(10)
    }

    postCountLabel.snp.makeConstraints {
      $0.top.equalTo(tagLabel.snp.bottom).offset(16)
      $0.trailing.equalToSuperview().inset(20)
    }

    dividerView.snp.makeConstraints {
      $0.bottom.leading.trailing.equalToSuperview()
      $0.height.equalTo(10)
    }
  }

  func configure(tag: String, isFollow: Bool, count: Int) {
    postCountLabel.text = "\(count)개"
    tagLabel.text = tag
    followButton.isSelected = isFollow
  }
}

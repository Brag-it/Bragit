//
//  FavoriteMessageCell.swift
//  Bragit
//
//  Created by seongjun cho on 8/28/25.
//

import UIKit

import SnapKit
import Then

final class FavoriteMessageCell: UICollectionViewCell {

  static let identifier = "FavoriteMessageCell"

  private let messageLabel = UILabel().then {
    $0.font = .pretendard(size: 16, weight: .semibold)
    $0.textColor = .grayScale700
    $0.textAlignment = .center
    $0.numberOfLines = 1
  }

  private let subMessageLabel = UILabel().then {
    $0.font = .pretendard(size: 14)
    $0.textColor = .grayScale400
    $0.textAlignment = .center
    $0.numberOfLines = 1
  }

  private let dividerView = UIView().then {
    $0.backgroundColor = .grayScale50
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    contentView.addSubview(messageLabel)
    contentView.addSubview(subMessageLabel)
    contentView.addSubview(dividerView)

    messageLabel.snp.makeConstraints {
      $0.bottom.equalTo(self.snp.centerY).offset(3)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    subMessageLabel.snp.makeConstraints {
      $0.top.equalTo(self.snp.centerY).offset(3)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    dividerView.snp.makeConstraints {
      $0.bottom.leading.trailing.equalToSuperview()
      $0.height.equalTo(10)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(type: FavoriteReactor.PostType) {
    switch type {
    case .emptyTag:
      messageLabel.text = "아직 관심태그가 없어요"
      subMessageLabel.text = "마음에 드는 태그를 관심 지정해 보세요"
    case .emptyUser:
      messageLabel.text = "아직 팔로우한 사용자가 없어요"
      subMessageLabel.text = "마음에 드는 사용자를 팔로우해 보세요"
    default:
      messageLabel.text = ""
      subMessageLabel.text = ""
    }
  }
}

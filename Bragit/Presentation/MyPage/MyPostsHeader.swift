//
//  MyPostsHeader.swift
//  Bragit
//
//  Created by seongjun cho on 9/1/25.
//

import UIKit

import SnapKit
import Then

final class MyPostsHeader: UICollectionReusableView {
  static let identifier = "MyPostsHeader"

  private let titleLabel = UILabel().then {
    $0.font = .pretendard(size: 18, weight: .semibold)
    $0.textColor = .grayScale900
    $0.text = "내 게시물"
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(titleLabel)

    titleLabel.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.leading.equalToSuperview().offset(20)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

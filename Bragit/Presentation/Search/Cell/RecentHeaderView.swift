//
//  RecentHeaderView.swift
//  Bragit
//
//  Created by 이태윤 on 9/8/25.
//
import UIKit

import SnapKit
import Then
import RxSwift

final class RecentHeaderView: UICollectionReusableView {
  static let identifier = "RecentHeaderView"
  var disposeBag = DisposeBag()

  private let imageView = UIImageView().then {
    $0.image = .clock
    $0.tintColor = .grayScale400
  }
  private let titleLabel = UILabel().then {
    $0.font = .pretendard(size: 14, weight: .medium)
    $0.text = "최근 검색"
    $0.textColor = .grayScale400
  }

  let deleteAllButton = UIButton(type: .system).then {
    $0.setTitle("전체 삭제", for: .normal)
    $0.titleLabel?.font = .pretendard(size: 14, weight: .medium)
    $0.tintColor = .grayScale400
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(imageView)
    addSubview(titleLabel)
    addSubview(deleteAllButton)
    imageView.snp.makeConstraints {
      $0.top.equalToSuperview().inset(12)
      $0.leading.equalToSuperview().inset(20)
      $0.width.height.equalTo(22)
    }

    titleLabel.snp.makeConstraints {
      $0.leading.equalTo(imageView.snp.trailing).offset(6)
      $0.centerY.equalTo(imageView)
    }

    deleteAllButton.snp.makeConstraints {
      $0.trailing.equalToSuperview().inset(20)
      $0.centerY.equalTo(imageView)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
  }
}

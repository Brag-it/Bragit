//
//  DescriptionCell.swift
//  Bragit
//
//  Created by 이태윤 on 9/1/25.
//
import UIKit

import SnapKit
import Then
import RxSwift
import RxCocoa

final class DescriptionCell: UICollectionViewCell {
  static let identifier: String = "DescriptionCell"
  var disposeBag = DisposeBag()

  let descriptionLabel = DescriptionTextView().then {
    $0.placeholder = "내용을 잘 나타내는 설명을 입력해 주세요"
    $0.font = .pretendard(size: 15)
    $0.showsVerticalScrollIndicator = false
    $0.layer.cornerRadius = 14
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16) // 내부 여백
    $0.layer.borderWidth = 1
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.addSubview(descriptionLabel)

    descriptionLabel.snp.makeConstraints {
      $0.directionalEdges.equalToSuperview()
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(text: String) {
    descriptionLabel.text = text
  }
}

//
//  ProfileListView.swift
//  Bragit
//
//  Created by seongjun cho on 9/3/25.
//

import UIKit

import SnapKit
import Then

final class ProfileListView: UIView {

  private let headerView = UIView()

  let backButton = UIButton().then {
    $0.setImage(.back, for: .normal)
  }

  lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())

  var titleLabel = UILabel().then {
    $0.numberOfLines = 1
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
  }

  var subTitleLabel = UILabel().then {
    $0.numberOfLines = 1
    $0.font = .pretendard(size: 14)
    $0.textColor = .grayScale700
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
    self.backgroundColor = .white
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    addSubview(headerView)
    addSubview(collectionView)
    headerView.addSubview(backButton)
    headerView.addSubview(titleLabel)
    headerView.addSubview(subTitleLabel)

    headerView.snp.makeConstraints {
      $0.top.leading.trailing.equalTo(self.safeAreaLayoutGuide)
      $0.height.equalTo(58)
    }

    backButton.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.leading.equalToSuperview().offset(20)
      $0.width.height.equalTo(24)
    }

    titleLabel.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.bottom.equalTo(headerView.snp.centerY).offset(-2)
    }

    subTitleLabel.snp.makeConstraints {
      $0.centerX.equalToSuperview()
      $0.top.equalTo(headerView.snp.centerY).offset(2)
    }

    collectionView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom)
      $0.leading.trailing.bottom.equalToSuperview()
    }
  }

  private func createLayout() -> UICollectionViewLayout {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .absolute(65))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .absolute(65))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    let section = NSCollectionLayoutSection(group: group)

    return UICollectionViewCompositionalLayout(section: section)
  }
}

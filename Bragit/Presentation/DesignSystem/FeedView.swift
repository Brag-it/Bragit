//
//  FeedView.swift
//  Bragit
//
//  Created by seongjun cho on 8/26/25.
//

import UIKit

import Then
import SnapKit

class FeedView: UIView {

  lazy var collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: makeCollectionViewLayout()).then {
      $0.showsVerticalScrollIndicator = false
      $0.backgroundColor = .white
    }

  private lazy var dataSource = makeCollectionViewDataSource(self.collectionView)

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(collectionView)

    collectionView.snp.makeConstraints {
      $0.top.leading.bottom.trailing.equalToSuperview()
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func makeCollectionViewLayout() -> UICollectionViewCompositionalLayout {
    return UICollectionViewCompositionalLayout { (_, _) -> NSCollectionLayoutSection? in

      let item = NSCollectionLayoutItem(
        layoutSize: .init(
          widthDimension: .fractionalWidth(1.0),
          heightDimension: .estimated(200)))

      let group = NSCollectionLayoutGroup.vertical(
        layoutSize: .init(
          widthDimension: .fractionalWidth(1.0),
          heightDimension: .estimated(200)),
        subitems: [item])

      let section = NSCollectionLayoutSection(group: group)

      return section
    }
  }

  func dataApply(data: [Post]) {
    var snapshot = NSDiffableDataSourceSnapshot<Int, Post>()

    snapshot.appendSections([0])
    snapshot.appendItems(data, toSection: 0)

    dataSource.apply(snapshot, animatingDifferences: true)
  }

  private func makeCollectionViewDataSource(
    _ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<Int, Post> {

      // 셀 설정
      let cellRegistration = UICollectionView.CellRegistration<PostCell, Post> { cell, _, item in
        cell.configure(data: item)
      }

      // 아이템별 데이터 소스 등록
      let dataSource = UICollectionViewDiffableDataSource<Int, Post>(
        collectionView: collectionView) { collectionView, indexPath, item in
          return collectionView
            .dequeueConfiguredReusableCell(
              using: cellRegistration,
              for: indexPath,
              item: item
            )
        }

      return dataSource
    }
}

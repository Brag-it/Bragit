//
//  FeedView.swift
//  Bragit
//
//  Created by seongjun cho on 8/26/25.
//

import UIKit

import Then
import SnapKit
import RxRelay

class FeedView: UIView {

  let followDidTap = PublishRelay<Post>()
  let tagDidTap = PublishRelay<Tag>()

  lazy var collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: makeCollectionViewLayout()).then {
      $0.showsVerticalScrollIndicator = false
      $0.backgroundColor = .white
    }

  lazy var dataSource = makeCollectionViewDataSource(self.collectionView)

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

  func reconfigurePosts(_ posts: [Post]) {
    var snapshot = dataSource.snapshot()
    let allItemsInSnapshot = snapshot.itemIdentifiers

    let itemsToReconfigure = posts
      .filter { allItemsInSnapshot.contains($0) }

    if !itemsToReconfigure.isEmpty {
      snapshot.reconfigureItems(itemsToReconfigure)
      dataSource.apply(snapshot, animatingDifferences: false)
    }
  }

  private func makeCollectionViewDataSource(
    _ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<Int, Post> {

      // 셀 설정
      let cellRegistration = UICollectionView.CellRegistration<PostCell, Post> { [weak self] cell, _, item in
        guard let self = self else { return }
        cell.configure(data: item)

        cell.followDidTap
          .bind(to: self.followDidTap)
          .disposed(by: cell.reusableDisposeBag)
        cell.tagsView.tagDidTap
          .bind(to: self.tagDidTap)
          .disposed(by: cell.reusableDisposeBag)
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

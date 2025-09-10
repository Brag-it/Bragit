//
//  FavoriteFeedView.swift
//  Bragit
//
//  Created by seongjun cho on 8/27/25.
//

import UIKit
import RxSwift
import RxRelay

import Dependencies

enum FavoriteItem: Hashable {
  case message(FavoriteReactor.PostType)
  case post(Post)
}

final class FavoriteFeedView: UIView {

  let tagDidTap = PublishRelay<Tag>()
  let postTagDidTap = PublishRelay<Tag>()
  let followDidTap = PublishRelay<Post>()
  let userDidTap = PublishRelay<Post>()
  let refreshRelay = PublishRelay<Void>()
  let refreshControl = UIRefreshControl()
  private let disposeBag = DisposeBag()

  private var postType: FavoriteReactor.PostType = .tag([])
  private var selectedTag: Tag?

  lazy var collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: makeCollectionViewLayout()).then {
      $0.showsVerticalScrollIndicator = false
      $0.backgroundColor = .white
      $0.refreshControl = refreshControl
    }

  lazy var dataSource = makeFavoriteCollectionViewDataSource(self.collectionView)

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(collectionView)

    collectionView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }

    refreshControl.rx.controlEvent(.valueChanged)
      .bind(to: refreshRelay)
      .disposed(by: disposeBag)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func makeCollectionViewLayout() -> UICollectionViewCompositionalLayout {
    return UICollectionViewCompositionalLayout { [weak self] (sectionIndex, _) -> NSCollectionLayoutSection? in
      guard let self = self else { return nil }
      var isMessageSection = false
      switch self.postType {
      case .emptyTag, .emptyUser:
        isMessageSection = true
      case .tag, .user:
        isMessageSection = false
      }

      if isMessageSection && sectionIndex == 0 {
        // 메세지 셀
        let item = NSCollectionLayoutItem(
          layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(170)))
        let group = NSCollectionLayoutGroup.vertical(
          layoutSize: .init(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(170)),
          subitems: [item])
        return NSCollectionLayoutSection(group: group)
      } else {
        // 게시글 셀
        let item = NSCollectionLayoutItem(
          layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(200)))
        let group = NSCollectionLayoutGroup.vertical(
          layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(200)), subitems: [item])
        let section = NSCollectionLayoutSection(group: group)

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(80))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
          layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        header.pinToVisibleBounds = true
        section.boundarySupplementaryItems = [header]

        return section
      }
    }
  }

  private func makeFavoriteCollectionViewDataSource(
    _ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<Int, FavoriteItem> {

      let messageCellRegistration = UICollectionView
        .CellRegistration<FavoriteMessageCell, FavoriteReactor.PostType> { cell, _, item in
        cell.configure(type: item)
      }

      let postCellRegistration = UICollectionView.CellRegistration<PostCell, Post> { [weak self] cell, _, item in
        guard let self = self else { return }
        cell.configure(data: item)

        cell.followDidTap
          .bind(to: self.followDidTap)
          .disposed(by: cell.reusableDisposeBag)

        cell.userDidTap
          .bind(to: self.userDidTap)
          .disposed(by: cell.reusableDisposeBag)

        cell.tagsView.tagDidTap
          .bind(to: self.postTagDidTap)
          .disposed(by: cell.reusableDisposeBag)
      }

      let headerRegistration = UICollectionView.SupplementaryRegistration<FavoriteSectionHeaderView>(
        elementKind: UICollectionView.elementKindSectionHeader
      ) { [weak self] supplementaryView, _, _ in
        guard let self = self else { return }
        supplementaryView.configure(postType: self.postType, selectedTag: self.selectedTag)
      }

      let dataSource = UICollectionViewDiffableDataSource<Int, FavoriteItem>(
        collectionView: collectionView) { collectionView, indexPath, item in
          switch item {
          case .message(let postType):
            return collectionView.dequeueConfiguredReusableCell(
              using: messageCellRegistration, for: indexPath, item: postType)
          case .post(let post):
            return collectionView.dequeueConfiguredReusableCell(using: postCellRegistration, for: indexPath, item: post)
          }
        }

      dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
        guard let self = self else { return nil }
        if kind == UICollectionView.elementKindSectionHeader {
          let header = collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
          header.tagDidTap
            .bind(to: self.tagDidTap)
            .disposed(by: header.disposeBag)
          return header
        }
        return nil
      }

      return dataSource
    }

  func dataApply(posts: [Post], postType: FavoriteReactor.PostType, selectedTag: Tag?) {
    self.postType = postType
    self.selectedTag = selectedTag

    var snapshot = NSDiffableDataSourceSnapshot<Int, FavoriteItem>()
    var isMessageState = false

    switch self.postType {
    case .emptyTag, .emptyUser:
      isMessageState = true
    case .tag, .user:
      isMessageState = false
    }

    if isMessageState {
      snapshot.appendSections([0])
      snapshot.appendItems([.message(postType)], toSection: 0)
    }

    if !posts.isEmpty {
      let sectionIndex = isMessageState ? 1 : 0
      snapshot.appendSections([sectionIndex])
      snapshot.appendItems(posts.map { .post($0) }, toSection: sectionIndex)
    }

    dataSource.apply(snapshot, animatingDifferences: true)
  }

  func reconfigurePosts(_ posts: [Post]) {
    var snapshot = dataSource.snapshot()
    let allItemsInSnapshot = snapshot.itemIdentifiers

    let itemsToReconfigure = posts
      .map { FavoriteItem.post($0) }
      .filter { allItemsInSnapshot.contains($0) }

    if !itemsToReconfigure.isEmpty {
      snapshot.reconfigureItems(itemsToReconfigure)
      dataSource.apply(snapshot, animatingDifferences: false)
    }
  }
}

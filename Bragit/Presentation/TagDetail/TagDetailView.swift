//
//  TagDetailView.swift
//  Bragit
//
//  Created by seongjun cho on 9/4/25.
//

import UIKit

import Then
import SnapKit
import RxRelay
import RxSwift

enum TagDetailItem: Hashable {
  case tagInfo(String, Bool, Int)
  case post(Post)
}

class TagDetailView: UIView {

  private let headerView = UIView().then {
    $0.backgroundColor = .white
  }

  private let tagLabel = UILabel().then {
    $0.text = "태그"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
  }

  let backButton = UIButton().then {
    $0.setImage(.back, for: .normal)
  }

  let choiceButton = UIButton().then {
    $0.setImage(.drop, for: .normal)
    $0.setTitle("태그", for: .normal)
    $0.setTitleColor(UIColor(red: 0.34, green: 0.34, blue: 0.34, alpha: 1), for: .normal)
    $0.titleLabel?.font = .pretendard(size: 18, weight: .semibold)
    $0.semanticContentAttribute = .forceRightToLeft
  }

  lazy var collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: makeCollectionViewLayout()).then {
      $0.showsVerticalScrollIndicator = false
      $0.backgroundColor = .white
    }

  lazy var dataSource = makeCollectionViewDataSource(self.collectionView)

  let followDidTap = PublishRelay<Post>()
  let tagFollowDidTap = PublishRelay<Void>()
  let userDidTap = PublishRelay<Post>()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .white

    setupUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    addSubview(headerView)
    headerView.addSubview(tagLabel)
    headerView.addSubview(backButton)
    addSubview(collectionView)

    headerView.snp.makeConstraints {
      $0.top.leading.trailing.equalTo(self.safeAreaLayoutGuide)
      $0.height.equalTo(58)
    }

    tagLabel.snp.makeConstraints {
      $0.centerY.centerX.equalToSuperview()
    }

    backButton.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.leading.equalToSuperview().inset(20)
    }

    collectionView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom)
      $0.leading.trailing.bottom.equalTo(self.safeAreaLayoutGuide)
    }
  }

  func makeCollectionViewLayout() -> UICollectionViewCompositionalLayout {
    return UICollectionViewCompositionalLayout { (sectionIndex, _) -> NSCollectionLayoutSection? in

      if sectionIndex == 0 {
        // 태그정보 셀
        let item = NSCollectionLayoutItem(
          layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(123)))
        let group = NSCollectionLayoutGroup.vertical(
          layoutSize: .init(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(123)),
          subitems: [item])
        return NSCollectionLayoutSection(group: group)
      } else {
        // 게시글 셀
        let item = NSCollectionLayoutItem(
          layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(200)))
        let group = NSCollectionLayoutGroup.vertical(
          layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(200)), subitems: [item])

        return NSCollectionLayoutSection(group: group)
      }
    }
  }

  private func makeCollectionViewDataSource(
    _ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<Int, TagDetailItem> {

      let tagInformCellRegistration = UICollectionView.CellRegistration<TagInformCell, (String, Bool, Int)> {
        [weak tagFollowDidTap] cell, _, item in
        guard let tagFollowDidTap = tagFollowDidTap else { return }
        cell.configure(tag: item.0, isFollow: item.1, count: item.2)
        cell.followButton.rx.tap
          .bind(to: tagFollowDidTap)
          .disposed(by: cell.disposeBag)
      }

      let postCellRegistration = UICollectionView.CellRegistration<PostCell, Post> { cell, _, item in
        cell.configure(data: item)
        cell.followDidTap
          .bind(to: self.followDidTap)
          .disposed(by: cell.reusableDisposeBag)
        cell.userDidTap
          .bind(to: self.userDidTap)
          .disposed(by: cell.reusableDisposeBag)
      }

      let dataSource = UICollectionViewDiffableDataSource<Int, TagDetailItem>(
        collectionView: collectionView) { collectionView, indexPath, item in
          switch item {
          case .tagInfo(let tag, let isFollow, let count):
            return collectionView.dequeueConfiguredReusableCell(
              using: tagInformCellRegistration, for: indexPath, item: (tag, isFollow, count))
          case .post(let post):
            return collectionView.dequeueConfiguredReusableCell(using: postCellRegistration, for: indexPath, item: post)
          }
        }

      return dataSource
    }

  func dataApply(tag: String, isFollow: Bool, postCount: Int, posts: [Post]) {
    var snapshot = NSDiffableDataSourceSnapshot<Int, TagDetailItem>()

    snapshot.appendSections([0])
    snapshot.appendItems([.tagInfo(tag, isFollow, postCount)], toSection: 0)
    snapshot.appendSections([1])
    snapshot.appendItems(posts.map { .post($0) }, toSection: 1)

    dataSource.apply(snapshot)
  }

  func reconfigurePosts(_ posts: [Post]) {
    var snapshot = dataSource.snapshot()
    let currentPostItemsInSnapshot = snapshot.itemIdentifiers(inSection: 1).compactMap { item -> Post? in
      if case .post(let post) = item { return post }
      return nil
    }

    let itemsToReconfigure = posts.filter { post in
      currentPostItemsInSnapshot.contains { $0.id == post.id }
    }.compactMap { post -> TagDetailItem? in
      return .post(post)
    }

    if !itemsToReconfigure.isEmpty {
      snapshot.reconfigureItems(itemsToReconfigure)
      dataSource.apply(snapshot, animatingDifferences: false)
    }
  }
}

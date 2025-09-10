//
//  UserProfileView.swift
//  Bragit
//
//  Created by seongjun cho on 9/9/25.
//

import UIKit

import SnapKit
import Then
import RxRelay
import RxSwift
import Kingfisher

enum UserProfileItem: Hashable {
  case userInfo(Profile)
  case post(Post)
}

final class UserProfileView: UIView {

  var disposeBag = DisposeBag()
  let tagDidTap = PublishRelay<Tag>()
  let followDidTap = PublishRelay<Void>()

  private let headerView = UIView().then {
    $0.backgroundColor = .white
  }

  let kebabButton = UIButton().then {
    $0.setImage(.kebab.withRenderingMode(.alwaysOriginal).withTintColor(.grayScale600), for: .normal)
  }

  let backButton = UIButton().then {
    $0.setImage(.back, for: .normal)
  }

  private let userProfileLabel = UILabel().then {
    $0.text = "프로필"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
  }

  lazy var collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: makeCollectionViewLayout()).then {
      $0.showsVerticalScrollIndicator = false
      $0.backgroundColor = .white
  }

  lazy var dataSource = makeCollectionViewDataSource(self.collectionView)

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
    headerView.addSubview(userProfileLabel)
    headerView.addSubview(kebabButton)
    headerView.addSubview(backButton)
    addSubview(collectionView)

    headerView.snp.makeConstraints {
      $0.top.leading.trailing.equalTo(self.safeAreaLayoutGuide)
      $0.height.equalTo(58)
    }

    userProfileLabel.snp.makeConstraints {
      $0.centerY.centerX.equalToSuperview()
    }

    kebabButton.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.trailing.equalToSuperview().inset(20)
    }

    backButton.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.leading.equalToSuperview().offset(20)
    }

    collectionView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom)
      $0.leading.trailing.equalTo(self.safeAreaLayoutGuide)
      $0.bottom.equalToSuperview()
    }
  }

  func makeCollectionViewLayout() -> UICollectionViewCompositionalLayout {
    return UICollectionViewCompositionalLayout { (sectionIndex, _) -> NSCollectionLayoutSection? in

      if sectionIndex == 0 {
        // 유저정보 셀
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

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(66))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
          layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

        section.boundarySupplementaryItems = [header]

        return section
      }
    }
  }

  private func makeCollectionViewDataSource(
    _ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<Int, UserProfileItem> {

      let profilCellRegistration = UICollectionView.CellRegistration<UserProfileCell, Profile> {
        [followDidTap] cell, _, item in
        cell.configure(profile: item)
        cell.followButton.rx.tap
          .bind(to: followDidTap)
          .disposed(by: cell.disposeBag)
      }

      let postCellRegistration = UICollectionView.CellRegistration<PostCell, Post> { cell, _, item in
        cell.configure(data: item)
        cell.tagsView.tagDidTap
          .bind(to: self.tagDidTap)
          .disposed(by: cell.reusableDisposeBag)
      }

      let headerRegistration = UICollectionView.SupplementaryRegistration<MyPostsHeader>(
        elementKind: UICollectionView.elementKindSectionHeader) { cell, _, _ in
          cell.setTitle("게시글")
        }

      let dataSource = UICollectionViewDiffableDataSource<Int, UserProfileItem>(
        collectionView: collectionView) { collectionView, indexPath, item in
          switch item {
          case .userInfo(let profile):
            return collectionView.dequeueConfiguredReusableCell(
              using: profilCellRegistration, for: indexPath, item: profile)
          case .post(let post):
            return collectionView.dequeueConfiguredReusableCell(using: postCellRegistration, for: indexPath, item: post)
          }
        }

      dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
        if kind == UICollectionView.elementKindSectionHeader {
          return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        } else {
          return nil
        }
      }

      return dataSource
    }

  func dataApply(profile: Profile, posts: [Post]) {
    var snapshot = NSDiffableDataSourceSnapshot<Int, UserProfileItem>()

    snapshot.appendSections([0])
    snapshot.appendItems([.userInfo(profile)], toSection: 0)
    snapshot.appendSections([1])
    snapshot.appendItems(posts.map { .post($0) }, toSection: 1)

    dataSource.apply(snapshot)
  }
}

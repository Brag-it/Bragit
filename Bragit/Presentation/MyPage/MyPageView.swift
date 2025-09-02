//
//  MyPageView.swift
//  Bragit
//
//  Created by seongjun cho on 9/1/25.
//

import UIKit

import SnapKit
import Then

final class MyPageView: UIView {

  private let headerView = UIView().then {
    $0.backgroundColor = .white
  }

  private let settingButton = UIButton().then {
    $0.setTitle("설정", for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16)
    $0.setTitleColor(.grayScale900, for: .normal)
  }

  private let myPageLabel = UILabel().then {
    $0.text = "마이페이지"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
  }

  let MyPageCollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()).then {

  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .white
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    addSubview(headerView)
    headerView.addSubview(myPageLabel)

    headerView.snp.makeConstraints {
      $0.top.leading.trailing.equalTo(self.safeAreaLayoutGuide)
      $0.height.equalTo(58)
    }

    myPageLabel.snp.makeConstraints {
      $0.centerY.centerX.equalToSuperview()
    }

    settingButton.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.trailing.equalToSuperview().inset(20)
    }
  }

  func makeCollectionViewLayout() -> UICollectionViewCompositionalLayout {
    return UICollectionViewCompositionalLayout { [weak self] (sectionIndex, _) -> NSCollectionLayoutSection? in
      guard let self = self else { return nil }

      if sectionIndex == 0 {
        // 유저정보 셀
        let item = NSCollectionLayoutItem(
          layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(170)))
        let group = NSCollectionLayoutGroup.vertical(
          layoutSize: .init(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(165)),
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

  private func makeFavoriteCollectionViewDataSource(
    _ collectionView: UICollectionView) -> UICollectionViewDiffableDataSource<Int, FavoriteItem> {

      let messageCellRegistration = UICollectionView
        .CellRegistration<FavoriteMessageCell, FavoriteReactor.PostType> { cell, _, item in
        cell.configure(type: item)
      }

      let postCellRegistration = UICollectionView.CellRegistration<PostCell, Post> { [weak self] cell, _, item in
        guard let self = self else { return }
        cell.configure(data: item)
      }

      let headerRegistration = UICollectionView.SupplementaryRegistration<FavoriteSectionHeaderView>(
        elementKind: UICollectionView.elementKindSectionHeader
      ) { _, _, _ in }

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

      dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
        if kind == UICollectionView.elementKindSectionHeader {
          return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        } else {
          return nil
        }
      }

      return dataSource
    }
}

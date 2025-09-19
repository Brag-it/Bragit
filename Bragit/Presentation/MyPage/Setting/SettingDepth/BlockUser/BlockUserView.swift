//
//  BlockUserView.swift
//  Bragit
//
//  Created by seongjun cho on 9/18/25.
//

import UIKit

import SnapKit
import Then
import RxRelay
import RxSwift

enum BlockUserSection: Int {
  case userList
  case empty
}

enum BlockUserItem: Hashable {
  case user(User)
  case empty
}

final class BlockUserView: UIView {

  private let headerView = UIView()

  let backButton = UIButton().then {
    $0.setImage(.back, for: .normal)
  }

  lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())

  let blockDidTap = PublishRelay<User>()

  var titleLabel = UILabel().then {
    $0.numberOfLines = 1
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
    $0.text = "차단한 유저"
  }

  var subTitleLabel = UILabel().then {
    $0.numberOfLines = 1
    $0.font = .pretendard(size: 14)
    $0.textColor = .grayScale700
  }

  lazy var dataSource = makeDataSource()

  let disposeBag = DisposeBag()

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
    return UICollectionViewCompositionalLayout { [weak self] (sectionIndex, _) -> NSCollectionLayoutSection? in
      guard let self = self else { return nil }

      let snapshot = self.dataSource.snapshot()
      guard sectionIndex < snapshot.sectionIdentifiers.count else { return nil }

      let sectionType = snapshot.sectionIdentifiers[sectionIndex]

      switch sectionType {
      case .userList:
        let itemSize = NSCollectionLayoutSize(
          widthDimension: .fractionalWidth(1.0),
          heightDimension: .absolute(65))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
          widthDimension: .fractionalWidth(1.0),
          heightDimension: .absolute(65))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        return NSCollectionLayoutSection(group: group)
      case .empty:
        let itemSize = NSCollectionLayoutSize(
          widthDimension: .fractionalWidth(1.0),
          heightDimension: .fractionalHeight(0.9))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
          widthDimension: .fractionalWidth(1.0),
          heightDimension: .fractionalHeight(0.9))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        return NSCollectionLayoutSection(group: group)
      }
    }
  }

  private func makeDataSource() -> UICollectionViewDiffableDataSource<BlockUserSection, BlockUserItem> {
    let userCellRegistration = UICollectionView.CellRegistration<BlockListCell, User> {
      (cell, _, item) in
      cell.configure(user: item)
      cell.blockDidTap
        .map { _ in item }
        .bind(to: self.blockDidTap)
        .disposed(by: self.disposeBag)
    }

    let emptyCellRegistration = UICollectionView.CellRegistration<EmptyCell, Void> {
      (cell, _, _) in
      cell.configure(message: "차단된 유저가 없습니다.")
    }

    return UICollectionViewDiffableDataSource<BlockUserSection, BlockUserItem>(
      collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
        switch item {
        case .user(let user):
          return collectionView.dequeueConfiguredReusableCell(using: userCellRegistration, for: indexPath, item: user)
        case .empty:
          return collectionView.dequeueConfiguredReusableCell(using: emptyCellRegistration, for: indexPath, item: ())
        }
      }
  }

  func dataApply(data: [User]) {
    var snapshot = NSDiffableDataSourceSnapshot<BlockUserSection, BlockUserItem>()

    if data.isEmpty {
      snapshot.appendSections([.empty])
      snapshot.appendItems([.empty], toSection: .empty)
    } else {
      snapshot.appendSections([.userList])
      let userItems = data.map { BlockUserItem.user($0) }
      snapshot.appendItems(userItems, toSection: .userList)
    }

    dataSource.apply(snapshot, animatingDifferences: true)
  }
}

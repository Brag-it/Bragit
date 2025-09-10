//
//  SettingView.swift
//  Bragit
//
//  Created by seongjun cho on 9/2/25.
//

import UIKit

import SnapKit
import Then
import RxSwift
import RxCocoa

final class SettingView: UIView {

  private let headerView = UIView().then {
    $0.backgroundColor = .white
  }

  private let settingLabel = UILabel().then {
    $0.text = "설정"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
  }

  let backButton = UIButton().then {
    $0.setImage(.back, for: .normal)
  }

  private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
  private lazy var dataSource = makeDataSource()

  // MARK: - Data Models
  struct SettingItem: Hashable {
    let title: String
    let subtitle: String
  }

  let itemSelected = PublishRelay<SettingItem>() // 셀 선택 이벤트 방출

  let logoutButton = UIButton().then {
    $0.setTitle("로그아웃", for: .normal)
    $0.setTitleColor(.grayScale600, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 13, weight: .medium)
  }

  let cancelAccountButton = UIButton().then {
    $0.setTitle("회원탈퇴", for: .normal)
    $0.setTitleColor(.grayScale600, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 13, weight: .medium)
  }

  private let settingItems: [SettingItem] = [
    SettingItem(title: "이용 약관", subtitle: ""),
    SettingItem(title: "오픈소스 라이선스", subtitle: ""),
    //    SettingItem(title: "비밀번호 변경", subtitle: ""),
    SettingItem(title: "앱 버전", subtitle: "1.0.0")
  ]

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .white
    setupUI()
    applySnapshot()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    addSubview(headerView)
    headerView.addSubview(settingLabel)
    headerView.addSubview(backButton)
    addSubview(collectionView)
    addSubview(logoutButton)
    addSubview(cancelAccountButton)

    headerView.snp.makeConstraints {
      $0.top.leading.trailing.equalTo(self.safeAreaLayoutGuide)
      $0.height.equalTo(58)
    }

    settingLabel.snp.makeConstraints {
      $0.centerY.centerX.equalToSuperview()
    }

    backButton.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.leading.equalToSuperview().offset(20)
    }

    collectionView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom)
      $0.leading.trailing.bottom.equalTo(self.safeAreaLayoutGuide)
    }
    collectionView.delegate = self

    logoutButton.snp.makeConstraints {
      $0.bottom.equalTo(self.safeAreaLayoutGuide).inset(31)
      $0.trailing.equalTo(self.snp.centerX).offset(-16)
      $0.height.equalTo(cancelAccountButton.titleLabel?.font.lineHeight ?? .zero)
    }

    cancelAccountButton.snp.makeConstraints {
      $0.bottom.equalTo(self.safeAreaLayoutGuide).inset(31)
      $0.leading.equalTo(self.snp.centerX).offset(16)
      $0.height.equalTo(cancelAccountButton.titleLabel?.font.lineHeight ?? .zero)
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

  private func makeDataSource() -> UICollectionViewDiffableDataSource<Int, SettingItem> {
    let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SettingItem> {
      (cell, _, item) in
        var content = cell.defaultContentConfiguration()
        content.text = item.title

        if item.subtitle != "" {
          content.secondaryText = item.subtitle
        }

        cell.contentConfiguration = content
        cell.accessories = [.disclosureIndicator(
          displayed: .always,
          options: .init(reservedLayoutWidth: .custom(40), tintColor: .grayScale900))]
    }

    return UICollectionViewDiffableDataSource<Int, SettingItem>(collectionView: collectionView) {
      (collectionView: UICollectionView, indexPath: IndexPath, identifier: SettingItem) -> UICollectionViewCell? in
      return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
    }
  }

  private func applySnapshot() {
    var snapshot = NSDiffableDataSourceSnapshot<Int, SettingItem>()
    snapshot.appendSections([0])
    snapshot.appendItems(settingItems, toSection: 0)
    dataSource.apply(snapshot, animatingDifferences: true)
  }
}

extension SettingView: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    guard indexPath.item < settingItems.count else { return }
    itemSelected.accept(settingItems[indexPath.item])
  }
}

//
//  ProfileListViewController.swift
//  Bragit
//
//  Created by seongjun cho on 9/3/25.
//

import UIKit

import RxSwift
import RxCocoa
import ReactorKit
import RxRelay

class ProfileListViewController<H: Hashable>: UIViewController {

  lazy var dataSource = makeDataSource()
  let profileListView = ProfileListView()
  let followDidTap = PublishRelay<H>()

  var titleText: String {
    get {
      return profileListView.titleLabel.text ?? ""
    }
    set {
      profileListView.titleLabel.text = newValue
    }
  }

  var subTitleText: String {
    get {
      return profileListView.subTitleLabel.text ?? ""
    }
    set {
      profileListView.subTitleLabel.text = newValue
    }
  }

  var disposeBag = DisposeBag()

  override func loadView() {
    view = profileListView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.navigationBar.isHidden = true
  }

  func dataApply(data: [H]) {
    var snapshot = NSDiffableDataSourceSnapshot<Int, H>()
    snapshot.appendSections([0])
    snapshot.appendItems(data, toSection: 0)
    dataSource.apply(snapshot, animatingDifferences: true)
  }

  private func makeDataSource() -> UICollectionViewDiffableDataSource<Int, H> {
    let cellRegistration = UICollectionView.CellRegistration<ProfileListCell, H> {
      (cell, _, item) in
      cell.configure(data: item)
      cell.followDidTap
        .map { _ in item }
        .bind(to: self.followDidTap)
        .disposed(by: self.disposeBag)
    }

    return UICollectionViewDiffableDataSource<Int, H>(collectionView: profileListView.collectionView) {
      (collectionView: UICollectionView, indexPath: IndexPath, identifier: H) -> UICollectionViewCell? in
      return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
    }
  }

  func reload() {
    profileListView.collectionView.reloadData()
  }
}

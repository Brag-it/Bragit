//
//  LicenseViewController.swift
//  Bragit
//
//  Created by 이태윤 on 9/9/25.
//
import UIKit

import SnapKit
import Then
import RxSwift
import RxCocoa
import ReactorKit

final class LicenseViewController: UIViewController, View {
  var disposeBag = DisposeBag()

  private let headerView = UIView().then {
    $0.backgroundColor = .white
  }

  private let titleLabel = UILabel().then {
    $0.text = "오픈소스 라이선스"
    $0.font = .pretendard(size: 20, weight: .medium)
    $0.textColor = .grayScale900
  }

  private let backButton = UIButton().then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }

  private lazy var dataSource = setupDataSource(self.collectionView)

  private lazy var collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: createLayout()).then {
      $0.backgroundColor = .white
      $0.showsVerticalScrollIndicator = false
      $0.register(LicenseCell.self, forCellWithReuseIdentifier: LicenseCell.identifier)
    }
  init(reactor: LicenseReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    view.addSubview(headerView)
    headerView.addSubview(backButton)
    headerView.addSubview(titleLabel)
    headerView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(58)
    }

    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(20)
      $0.centerY.equalTo(headerView)
    }

    titleLabel.snp.makeConstraints {
      $0.centerX.equalTo(headerView)
      $0.centerY.equalTo(headerView)
      $0.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(20)
    }
    view.addSubview(collectionView)
    collectionView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom)
      $0.leading.trailing.bottom.equalToSuperview()
    }
  }

  func bind(reactor: LicenseReactor) {
    rx.viewDidLoad
      .map { LicenseReactor.Action.viewDidLoad }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    backButton.rx.tap
      .map { LicenseReactor.Action.didTapBack }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    reactor.state
      .map { $0.items }
      .observe(on: MainScheduler.instance)
      .subscribe { [weak self] items in
        self?.applySnapshot(items)
      }
      .disposed(by: disposeBag)

    collectionView.rx.itemSelected
      .do { [weak self] indexPath in
        self?.collectionView.deselectItem(at: indexPath, animated: true)
      }
      .map { LicenseReactor.Action.select(index: $0.item) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
  }

  // 리스트 형태
  private func createLayout() -> UICollectionViewCompositionalLayout {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .absolute(65)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .absolute(65)
    )
    let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)

    return UICollectionViewCompositionalLayout(section: section)
  }

  private func applySnapshot(_ results: [LicenseItem]) {
    var snapshot = NSDiffableDataSourceSnapshot<Int, LicenseItem>()
    snapshot.appendSections([0])
    snapshot.appendItems(results, toSection: 0)
    dataSource.apply(snapshot, animatingDifferences: true)
  }

  private func setupDataSource(
    _ collectionView: UICollectionView
  ) -> UICollectionViewDiffableDataSource<Int, LicenseItem> {
    return UICollectionViewDiffableDataSource<Int, LicenseItem>(
      collectionView: collectionView
    ) { collectionView, indexPath, item in
      guard let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: LicenseCell.identifier,
        for: indexPath
      ) as? LicenseCell else {
        return UICollectionViewCell()
      }

      cell.configure(main: item.name, sub: "1 license")
      return cell
    }
  }
}

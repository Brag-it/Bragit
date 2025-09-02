//
//  SearchTagViewController.swift
//  Bragit
//
//  Created by 이태윤 on 9/1/25.
//
import UIKit

import SnapKit
import Then
import ReactorKit
import RxSwift
import RxCocoa

final class SearchTagViewController: UIViewController, View {
  var disposeBag = DisposeBag()

  private let searchBar = SearchBar()

  private lazy var dataSource = setupDataSource(self.searchResultCollectionView)

  private lazy var searchResultCollectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: createLayout()).then {
    $0.backgroundColor = .white
    $0.showsVerticalScrollIndicator = false
    $0.keyboardDismissMode = .onDrag
  }

  init(reactor: SearchTagReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white

    setUIConstraints()

    // 더미 데이터 테스트용
    let dummyTags = ["Swift", "iOS", "ReactorKit", "RxSwift", "SnapKit", "Then"]
    applySnapshot(dummyTags)
  }

  // UI 설정
  private func setUIConstraints() {
    view.addSubview(searchBar)
    view.addSubview(searchResultCollectionView)

    searchBar.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide).inset(28)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    searchResultCollectionView.snp.makeConstraints {
      $0.top.equalTo(searchBar.snp.bottom)
      $0.leading.trailing.bottom.equalToSuperview()
    }
  }

  func bind(reactor: SearchTagReactor) {

  }

  // 리스트
  private func createLayout() -> UICollectionViewCompositionalLayout {
    var config = UICollectionLayoutListConfiguration(appearance: .plain)
    config.showsSeparators = false       // 구분선 안 보이게
    config.backgroundColor = .white      // 배경색
    return UICollectionViewCompositionalLayout.list(using: config)
  }

  private func applySnapshot(_ results: [String]) {
    var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
    snapshot.appendSections([0])
    snapshot.appendItems(results, toSection: 0)
    dataSource.apply(snapshot, animatingDifferences: true)
  }

  private func setupDataSource(
    _ collectionView: UICollectionView
  ) -> UICollectionViewDiffableDataSource<Int, String> {
    let registration = UICollectionView.CellRegistration<UICollectionViewListCell, String> { cell, _, title in
      var content = cell.defaultContentConfiguration()
      content.text = "# " + title
      content.textProperties.font = .pretendard(size: 15)
      content.textProperties.color = .grayScale900
      cell.contentConfiguration = content
    }

    return UICollectionViewDiffableDataSource<Int, String>(
      collectionView: collectionView
    ) { collectionView, indexPath, item in
      collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: item)
    }
  }
}

@available(iOS 17.0, *)
#Preview {
  let reactor = SearchTagReactor()
  return UINavigationController(rootViewController: SearchTagViewController(reactor: reactor))
}

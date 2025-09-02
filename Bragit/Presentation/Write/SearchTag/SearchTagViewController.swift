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

  private let heanderView = UIView().then {
    $0.backgroundColor = .grayScale600
    $0.layer.cornerRadius = 2
  }
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
  }

  // UI 설정
  private func setUIConstraints() {
    view.addSubview(heanderView)
    view.addSubview(searchBar)
    view.addSubview(searchResultCollectionView)

    heanderView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide).inset(16)
      $0.centerX.equalToSuperview()
      $0.width.equalTo(48)
      $0.height.equalTo(4)
    }
    searchBar.snp.makeConstraints {
      $0.top.equalTo(heanderView.snp.bottom).offset(16)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    searchResultCollectionView.snp.makeConstraints {
      $0.top.equalTo(searchBar.snp.bottom)
      $0.leading.trailing.bottom.equalToSuperview()
    }
  }

  func bind(reactor: SearchTagReactor) {
    let searchTextStream = (searchBar.textField.rx.text.orEmpty)
      .share(replay: 1)

    searchTextStream
      .map(SearchTagReactor.Action.updateSearchText)
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    let searchTrigger = Observable.merge(
      searchBar.searchButton.rx.tap.asObservable(),
      searchBar.textField.rx.controlEvent(.editingDidEndOnExit).asObservable()
    )

    searchTrigger
      .map { SearchTagReactor.Action.didTapSearchButton }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 바닥 감지 후 다음 페이지 로드
    searchResultCollectionView.rx.reachedBottom()
      .map { SearchTagReactor.Action.loadNextPage }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    reactor.state
      .map(\.searchResult)
      .distinctUntilChanged()
      .bind { [weak self] tag in
        guard let self else { return }
        applySnapshot(tag)
      }
      .disposed(by: disposeBag)

    searchResultCollectionView.rx.itemSelected
      .compactMap { [weak self] indexPath -> SearchTagReactor.Action? in
        guard let tag = self?.dataSource.itemIdentifier(for: indexPath) else { return nil }
        return .selectResult(tag)
      }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
  }

  // 리스트 형태
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
    let registration = UICollectionView.CellRegistration<UICollectionViewListCell, String> { cell, _, tags in
      var content = cell.defaultContentConfiguration()
      content.text = "# " + tags
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

//
//  SearchViewContoller.swift
//  Bragit
//
//  Created by 이태윤 on 9/6/25.
//
import UIKit

import SnapKit
import Then
import ReactorKit
import RxSwift
import RxCocoa

final class SearchViewController: UIViewController, View {
  var disposeBag = DisposeBag()

  private let headerView = UIView()

  private let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }

  private let searchBar = SearchBar()

  private lazy var dataSource = setupDataSource(self.searchCollectionView)

  private lazy var searchCollectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: createLayout()
  ).then {
    $0.backgroundColor = .white
    $0.keyboardDismissMode = .onDrag
    $0.showsVerticalScrollIndicator = false
  }

  init(reactor: SearchReactor) {
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
    view.addSubview(headerView)
    headerView.addSubview(backButton)
    headerView.addSubview(searchBar)
    view.addSubview(searchCollectionView)

    headerView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(64)
    }

    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().inset(20)
      $0.centerY.equalTo(headerView.snp.centerY)
      $0.width.equalTo(24)
    }

    searchBar.snp.makeConstraints {
      $0.leading.equalTo(backButton.snp.trailing).offset(16)
      $0.centerY.equalTo(headerView.snp.centerY)
      $0.trailing.equalToSuperview().inset(20)
    }

    searchCollectionView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom)
      $0.leading.trailing.bottom.equalToSuperview()
    }

  }

  func bind(reactor: SearchReactor) {
    backButton.rx.tap
      .map { SearchReactor.Action.didTapBack }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    let textField = searchBar.textField
    textField.rx.controlEvent(.editingChanged)
      .withLatestFrom(textField.rx.text.orEmpty)
      .distinctUntilChanged()
      .map(SearchReactor.Action.updateText)
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    Observable.merge(
      textField.rx.controlEvent(.editingDidEndOnExit).asObservable(),
      searchBar.searchButton.rx.tap.asObservable()
    )
    .map { SearchReactor.Action.result } // reactor must define `result` action, otherwise change to `.submit`
    .bind(to: reactor.action)
    .disposed(by: disposeBag)

    rx.viewDidAppear
      .take(1)
      .map { _ in SearchReactor.Action.viewDidLoad }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    reactor.state.map(\.recent)
      .distinctUntilChanged { ($0 ?? []) == ($1 ?? []) }
      .bind(with: self) { owner, recent in
        owner.applySnapshot(for: recent)
      }
      .disposed(by: disposeBag)

    searchCollectionView.rx.itemSelected
      .compactMap { [weak self] indexPath -> String? in
        guard let self,
              case let .recentKeyword(keyword) = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
        return keyword
      }
      .map(SearchReactor.Action.tapRecent)
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
  }

  private func createLayout() -> UICollectionViewCompositionalLayout {
    return UICollectionViewCompositionalLayout { sectionIndex, _ in
      switch sectionIndex {
      case 0:
        return self.recentSectionLaout()
      case 1:
        return self.suggestionsSectionLayout()
      case 2:
        return self.tagSectionLayout()
      case 3:
        return self.postSectionLayout()
      case 4:
        return self.userSectionLayout()
      default:
        return self.recentSectionLaout()
      }
    }
  }

  // 최근검색
  private func recentSectionLaout() -> NSCollectionLayoutSection {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .absolute(73)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .absolute(73)
    )
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = NSDirectionalEdgeInsets(top: 24, leading: 20, bottom: 16, trailing: 20)
    return section
  }

  // 검색중
  private func suggestionsSectionLayout() -> NSCollectionLayoutSection {
    let headerSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .absolute(22)
    )
    let header = NSCollectionLayoutBoundarySupplementaryItem(
      layoutSize: headerSize,
      elementKind: UICollectionView.elementKindSectionHeader,
      alignment: .top
    )

    let itemSize = NSCollectionLayoutSize(
      widthDimension: .absolute(160),
      heightDimension: .absolute(120)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let groupSize = NSCollectionLayoutSize(
      widthDimension: .absolute(160),
      heightDimension: .absolute(120)
    )

    let group = NSCollectionLayoutGroup.horizontal(
      layoutSize: groupSize,
      subitems: [item]
    )

    let section = NSCollectionLayoutSection(group: group)
    section.boundarySupplementaryItems = [header]
    section.orthogonalScrollingBehavior = .continuous
    section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 24, trailing: 20)
    section.interGroupSpacing = 6
    return section
  }

  // 태그
  private func tagSectionLayout() -> NSCollectionLayoutSection {
    var config = UICollectionLayoutListConfiguration(appearance: .plain)
    config.showsSeparators = false
    config.backgroundColor = .white
    return UICollectionViewCompositionalLayout.list(using: config)
  }

  // 게시물
  private func postSectionLayout() -> NSCollectionLayoutSection {
    let headerSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .absolute(22)
    )
    let header = NSCollectionLayoutBoundarySupplementaryItem(
      layoutSize: headerSize,
      elementKind: UICollectionView.elementKindSectionHeader,
      alignment: .top
    )

    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .absolute(201)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .absolute(201)
    )
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

    let section = NSCollectionLayoutSection(group: group)
    section.boundarySupplementaryItems = [header]
    section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 24, trailing: 20)
    return section
  }

  // 유저
  private func userSectionLayout() -> NSCollectionLayoutSection {
    let headerSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .absolute(22)
    )
    let header = NSCollectionLayoutBoundarySupplementaryItem(
      layoutSize: headerSize,
      elementKind: UICollectionView.elementKindSectionHeader,
      alignment: .top
    )

    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .absolute(201)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .absolute(201)
    )
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

    let section = NSCollectionLayoutSection(group: group)
    section.boundarySupplementaryItems = [header]
    section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 24, trailing: 20)
    return section
  }

  private func applySnapshot(
    recent: [String]?,
    suggestions: [String],
    tags: [SearchTagItem],
    posts: [SearchPostItem],
    users: [SearchUserItem],
    mode: SearchMode,          // .recent / .typingSuggestions / .results
    scope: SearchScope         // .tag / .post / .user
  ) {
    var snap = NSDiffableDataSourceSnapshot<SearchSection, SearchRow>()

    switch mode {
    case .recent:
      snap.appendSections([.recent])
      if let list = recent, !list.isEmpty {
        snap.appendItems(list.map { .recentKeyword($0) }, toSection: .recent)
      } else {
        // “최근 검색결과” 고정 셀을 헤더 섹션으로 두고 싶으면 .recent 앞에 .recentHeader 섹션을 따로 만들기
        snap.appendItems([.recentKeyword("최근 검색")], toSection: .recent) // 임시 placeholder 셀(커스텀 셀에서 스타일)
      }

    case .typingSuggestions:
      snap.appendSections([.suggestions])
      snap.appendItems(suggestions.map { .suggestion($0) }, toSection: .suggestions)

    case .results:
      switch scope {
      case .tag:
        snap.appendSections([.tagResults])
        snap.appendItems(tags.map { .tag($0) }, toSection: .tagResults)
      case .post:
        snap.appendSections([.postResults])
        snap.appendItems(posts.map { .post($0) }, toSection: .postResults)
      case .user:
        snap.appendSections([.userResults])
        snap.appendItems(users.map { .user($0) }, toSection: .userResults)
      }
    }

    dataSource.apply(snap, animatingDifferences: true)
  }

  private func setupDataSource(_ collectionView: UICollectionView)
  -> UICollectionViewDiffableDataSource<SearchSection, SearchRow> {
    let recentReg = UICollectionView.CellRegistration<RecentKeywordCell, String> { cell, _, keyword in
      cell.configure(with: keyword)
    }
    let suggReg = UICollectionView.CellRegistration<SuggestionCell, String> { cell, _, text in
      cell.configure(with: text)
    }
    let tagReg = UICollectionView.CellRegistration<SearchTagCell, SearchTagItem> { cell, _, item in
      cell.configure(with: item)
    }
    let postReg = UICollectionView.CellRegistration<PostCell, SearchPostItem> { cell, _, item in
      cell.configure(with: item)
    }
    let userReg = UICollectionView.CellRegistration<SearchUserCell, SearchUserItem> { cell, _, item in
      cell.configure(with: item)
    }

    // 2) 데이터소스
    let dataSource = UICollectionViewDiffableDataSource<SearchSection, SearchRow>(collectionView: collectionView) { collectionView, indexPath, row in
      switch row {
      case .recentKeyword(let keyword):
        return collectionView.dequeueConfiguredReusableCell(using: recentReg, for: indexPath, item: keyword)
      case .suggestion(let text):
        return collectionView.dequeueConfiguredReusableCell(using: suggReg, for: indexPath, item: text)
      case .tag(let item):
        return collectionView.dequeueConfiguredReusableCell(using: tagReg, for: indexPath, item: item)
      case .post(let item):
        return collectionView.dequeueConfiguredReusableCell(using: postReg, for: indexPath, item: item)
      case .user(let item):
        return collectionView.dequeueConfiguredReusableCell(using: userReg, for: indexPath, item: item)
      }
    }
    return dataSource
  }

}

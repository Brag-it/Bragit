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

  private let resultHeader = SearchHeaderView().then {
    $0.isHidden = true
  }

  private var resultHeaderHeight: Constraint?

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
    view.addSubview(resultHeader)
    view.addSubview(searchCollectionView)
    headerView.addSubview(backButton)
    headerView.addSubview(searchBar)

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

    // Result header pinned under headerView
    resultHeader.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom)
      $0.leading.trailing.equalToSuperview()
      resultHeaderHeight = $0.height.equalTo(0).constraint
    }

    searchCollectionView.snp.makeConstraints {
      $0.top.equalTo(resultHeader.snp.bottom)
      $0.leading.trailing.bottom.equalToSuperview()
    }
  }
  // swiftlint:disable cyclomatic_complexity
  func bind(reactor: SearchReactor) {
    rx.viewDidAppear
      .take(1)
      .map { _ in SearchReactor.Action.viewDidLoad }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

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

    let submitTrigger = Observable.merge(
      textField.rx.controlEvent(.editingDidEndOnExit).asObservable(),
      searchBar.searchButton.rx.tap.asObservable()
    )

    // 텍스트 상태
    reactor.state
      .map(\.text)
      .distinctUntilChanged()
      .bind(to: textField.rx.text)
      .disposed(by: disposeBag)

    submitTrigger
      .map { SearchReactor.Action.submit }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    searchCollectionView.rx.itemSelected
      .compactMap { [weak self] indexPath -> SearchRow? in
        guard let self else { return nil }

        searchCollectionView.deselectItem(at: indexPath, animated: true)

        return dataSource.itemIdentifier(for: indexPath)
      }
      .do { [weak self] _ in
        self?.view.endEditing(true)
      }
      .flatMap { row -> Observable<SearchReactor.Action> in
        switch row {

        case .recentKeyword(let text), .suggestion(let text):
          return .just(.submitWithQuery(text, true))

        case .tag(let item):
          return .just(.didTapTag(item.tag))

        case .post(let item):
          return .just(.didTapPost(item.post))

        case .user(let item):
          return .just(.didTapUser(item.user))

        default:
          return .empty()
        }
      }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    resultHeader.button(for: .tag).rx.tap
      .map { SearchReactor.Action.changeScope(.tag) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    resultHeader.button(for: .post).rx.tap
      .map { SearchReactor.Action.changeScope(.post) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    resultHeader.button(for: .user).rx.tap
      .map { SearchReactor.Action.changeScope(.user) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    reactor.state.map(\.scope).distinctUntilChanged()
      .map { scope -> SearchHeaderView.Tab in
        switch scope {
        case .tag:  return .tag
        case .post: return .post
        case .user: return .user
        }
      }
      .observe(on: MainScheduler.instance)
      .subscribe { [weak self] tab in
        self?.resultHeader.set(tab: tab, animated: true)
      }
      .disposed(by: disposeBag)

    reactor.state.map(\.mode)
      .distinctUntilChanged()
      .observe(on: MainScheduler.instance)
      .subscribe { [weak self] mode in
        guard let self else { return }
        let show = (mode == .results)
        self.resultHeader.isHidden = !show
        self.resultHeaderHeight?.update(offset: show ? 50 : 0)
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
      }
      .disposed(by: disposeBag)

    reactor.state
      .subscribe { [weak self] state in
        guard let self else { return }
        applySnapshot(
          recent: state.recent,
          suggestions: state.suggestions,
          tags: state.tagResults,
          posts: state.postResults,
          users: state.userResults,
          mode: state.mode,
          scope: state.scope
        )
      }
      .disposed(by: disposeBag)
  }
  // swiftlint:enable cyclomatic_complexity

  private func createLayout() -> UICollectionViewCompositionalLayout {
    let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
      guard let self else { return nil }
      let sections = self.dataSource.snapshot().sectionIdentifiers
      guard sectionIndex < sections.count else { return nil }
      let section = sections[sectionIndex]
      return self.layout(for: section)
    }
    let configuration = UICollectionViewCompositionalLayoutConfiguration()
    layout.configuration = configuration
    return layout
  }

  private func layout(for section: SearchSection) -> NSCollectionLayoutSection {
    switch section {
    case .recent:
      return recentSectionLayout()
    case .suggestions:
      return typingtagSectionLayout()
    case .tagResults:
      return tagSectionLayout()
    case .postResults:
      return postSectionLayout()
    case .userResults:
      return userSectionLayout()
    case .emptyResults:
      return emptySectionLayout()
    }
  }

  // 최근검색
  private func recentSectionLayout() -> NSCollectionLayoutSection {
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
      heightDimension: .absolute(49)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .absolute(49)
    )
    let group = NSCollectionLayoutGroup.vertical(
      layoutSize: groupSize,
      subitems: [item]
    )

    let section = NSCollectionLayoutSection(group: group)
    section.boundarySupplementaryItems = [header]
    section.contentInsets = .init(top: 14, leading: 0, bottom: 14, trailing: 0)
    return section
  }

  // 검색중
  private func typingtagSectionLayout() -> NSCollectionLayoutSection {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(200)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(200)
    )
    let group = NSCollectionLayoutGroup.vertical(
      layoutSize: groupSize,
      subitems: [item]
    )

    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    return section
  }

  // 태그
  private func tagSectionLayout() -> NSCollectionLayoutSection {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(300)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(300)
    )
    let group = NSCollectionLayoutGroup.vertical(
      layoutSize: groupSize,
      subitems: [item]
    )
    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    return section
  }

  // 게시글
  private func postSectionLayout() -> NSCollectionLayoutSection {
    let item = NSCollectionLayoutItem(
      layoutSize: .init(
        widthDimension: .fractionalWidth(1.0),
        heightDimension: .estimated(200)))

    let group = NSCollectionLayoutGroup.vertical(
      layoutSize: .init(
        widthDimension: .fractionalWidth(1.0),
        heightDimension: .estimated(200)),
      subitems: [item])

    let section = NSCollectionLayoutSection(group: group)
    return section
  }

  // 사용자
  private func userSectionLayout() -> NSCollectionLayoutSection {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(300)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(300)
    )
    let group = NSCollectionLayoutGroup.vertical(
      layoutSize: groupSize,
      subitems: [item]
    )

    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    return section
  }

  // 검색결과 없을 때
  private func emptySectionLayout() -> NSCollectionLayoutSection {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .fractionalHeight(1.0)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = .zero
    return section
  }

  private func applySnapshot(
    recent: [String]?,
    suggestions: [String],
    tags: [SearchTagItem],
    posts: [SearchPostItem],
    users: [SearchUserItem],
    mode: SearchMode,
    scope: SearchScope
  ) {
    var snapshot = NSDiffableDataSourceSnapshot<SearchSection, SearchRow>()

    switch mode {
    case .recent:
      applyRecentSnapshot(&snapshot, recent: recent)

    case .typingSuggestions:
      applyTypingSnapshot(&snapshot, suggestions: suggestions)

    case .results:
      applyResultsSnapshot(&snapshot, scope: scope, tags: tags, posts: posts, users: users)
    }

    dataSource.apply(snapshot, animatingDifferences: true)
  }

  private struct Registrations {
    let recent: UICollectionView.CellRegistration<RecentCell, String>
    let suggestion: UICollectionView.CellRegistration<UICollectionViewListCell, String>
    let tag: UICollectionView.CellRegistration<UICollectionViewListCell, SearchTagItem>
    let post: UICollectionView.CellRegistration<PostCell, SearchPostItem>
    let user: UICollectionView.CellRegistration<UserCell, SearchUserItem>
    let empty: UICollectionView.CellRegistration<EmptyCell, Void>
    let recentHeader: UICollectionView.SupplementaryRegistration<RecentHeaderView>
  }

  private func makeRegistrations() -> Registrations {
    let recentReg = UICollectionView.CellRegistration<RecentCell, String> { [weak self] cell, _, keyword in
      guard let self, let reactor = self.reactor else { return }
      cell.configure(text: keyword)
      cell.xMarker.rx.tap
        .map { SearchReactor.Action.deleteRecent(keyword) }
        .bind(to: reactor.action)
        .disposed(by: cell.disposeBag)
    }

    let suggestionReg = UICollectionView.CellRegistration<UICollectionViewListCell, String> { cell, _, item in
      var content = cell.defaultContentConfiguration()
      content.text = item
      content.textProperties.font = .pretendard(size: 15)
      content.textProperties.color = .grayScale900
      cell.contentConfiguration = content
    }

    let tagReg = UICollectionView.CellRegistration<UICollectionViewListCell, SearchTagItem> { cell, _, item in
      var content = cell.defaultContentConfiguration()
      content.image = .hashTag
      content.imageProperties.tintColor = .grayScale900
      content.imageProperties.reservedLayoutSize = CGSize(width: 20, height: 20)

      content.text = item.tag.tag

      content.textProperties.font = .pretendard(size: 15)
      content.textProperties.color = .grayScale900
      content.imageToTextPadding = 8
      cell.contentConfiguration = content
    }

    let postReg = UICollectionView.CellRegistration<PostCell, SearchPostItem> { cell, _, item in
      cell.configure(data: item.post)
    }

    let userReg = UICollectionView.CellRegistration<UserCell, SearchUserItem> { cell, _, item in
      cell.configure(user: item.user)
    }

    let emptyReg = UICollectionView.CellRegistration<EmptyCell, Void> { _, _, _ in }

    let recentHeaderReg = UICollectionView.SupplementaryRegistration<RecentHeaderView>(
      elementKind: UICollectionView.elementKindSectionHeader
    ) { [weak self] header, _, _ in
      guard let self, let reactor = self.reactor else { return }
      header.deleteAllButton.rx.tap
        .map { SearchReactor.Action.clearAllRecent }
        .bind(to: reactor.action)
        .disposed(by: header.disposeBag)
    }

    return Registrations(
      recent: recentReg,
      suggestion: suggestionReg,
      tag: tagReg,
      post: postReg,
      user: userReg,
      empty: emptyReg,
      recentHeader: recentHeaderReg
    )
  }

  private func makeCellProvider(
    with regs: Registrations) -> UICollectionViewDiffableDataSource<SearchSection, SearchRow>.CellProvider {
      return { collectionView, indexPath, row in
        switch row {
        case .recentKeyword(let keyword):
          return collectionView.dequeueConfiguredReusableCell(using: regs.recent, for: indexPath, item: keyword)
        case .suggestion(let text):
          return collectionView.dequeueConfiguredReusableCell(using: regs.suggestion, for: indexPath, item: text)
        case .tag(let item):
          return collectionView.dequeueConfiguredReusableCell(using: regs.tag, for: indexPath, item: item)
        case .post(let item):
          return collectionView.dequeueConfiguredReusableCell(using: regs.post, for: indexPath, item: item)
        case .user(let item):
          return collectionView.dequeueConfiguredReusableCell(using: regs.user, for: indexPath, item: item)
        case .empty:
          return collectionView.dequeueConfiguredReusableCell(using: regs.empty, for: indexPath, item: ())
        }
      }
    }

  private func makeSupplementaryProvider(
    with regs: Registrations
  ) -> UICollectionViewDiffableDataSource<SearchSection, SearchRow>.SupplementaryViewProvider {
    return { [weak self] collectionView, _, indexPath in
      guard let self else { return nil }
      let sectionKind = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
      switch sectionKind {
      case .recent:
        return collectionView.dequeueConfiguredReusableSupplementary(using: regs.recentHeader, for: indexPath)
      default:
        return nil
      }
    }
  }

  private func setupDataSource(_ collectionView: UICollectionView)
  -> UICollectionViewDiffableDataSource<SearchSection, SearchRow> {
    let regs = makeRegistrations()
    let dataSource = UICollectionViewDiffableDataSource<SearchSection, SearchRow>(
      collectionView: collectionView,
      cellProvider: makeCellProvider(with: regs)
    )
    dataSource.supplementaryViewProvider = makeSupplementaryProvider(with: regs)
    return dataSource
  }

  private func applyRecentSnapshot(
    _ snapshot: inout NSDiffableDataSourceSnapshot<SearchSection, SearchRow>,
    recent: [String]?
  ) {
    snapshot.appendSections([.recent])
    if let list = recent, !list.isEmpty {
      snapshot.appendItems(list.map { .recentKeyword($0) }, toSection: .recent)
    }
  }

  private func applyTypingSnapshot(
    _ snapshot: inout NSDiffableDataSourceSnapshot<SearchSection, SearchRow>,
    suggestions: [String]
  ) {
    guard !suggestions.isEmpty else { return }
    snapshot.appendSections([.suggestions])
    snapshot.appendItems(suggestions.map { .suggestion($0) }, toSection: .suggestions)
  }

  private func applyResultsSnapshot(
    _ snapshot: inout NSDiffableDataSourceSnapshot<SearchSection, SearchRow>,
    scope: SearchScope,
    tags: [SearchTagItem],
    posts: [SearchPostItem],
    users: [SearchUserItem]
  ) {
    switch scope {
    case .tag:
      if tags.isEmpty {
        snapshot.appendSections([.emptyResults])
        snapshot.appendItems([.empty], toSection: .emptyResults)
      } else {
        snapshot.appendSections([.tagResults])
        snapshot.appendItems(tags.map { .tag($0) }, toSection: .tagResults)
      }

    case .post:
      if posts.isEmpty {
        snapshot.appendSections([.emptyResults])
        snapshot.appendItems([.empty], toSection: .emptyResults)
      } else {
        snapshot.appendSections([.postResults])
        snapshot.appendItems(posts.map { .post($0) }, toSection: .postResults)
      }

    case .user:
      if users.isEmpty {
        snapshot.appendSections([.emptyResults])
        snapshot.appendItems([.empty], toSection: .emptyResults)
      } else {
        snapshot.appendSections([.userResults])
        snapshot.appendItems(users.map { .user($0) }, toSection: .userResults)
      }
    }
  }
}

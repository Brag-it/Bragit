//
//  PreviewViewController.swift
//  Bragit
//
//  Created by 이태윤 on 8/27/25.
//
import UIKit

import ReactorKit
import RxSwift
import RxCocoa

final class PreviewViewController: UIViewController, View {
  var disposeBag = DisposeBag()

  private let headerView = UIView()

  private let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }

  private let doneButton = UIButton(type: .system).then {
    $0.setTitle("확인", for: .normal)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16, weight: .medium)
    $0.backgroundColor = .primary400
    $0.layer.cornerRadius = 12
  }

  private let titleLabel = UILabel().then {
    $0.text = "글쓰기"
    $0.font = .pretendard(size: 16)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
    $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
  }

  private lazy var dataSource = setupDataSource(self.priviewCollectionView)

  private lazy var priviewCollectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: createLayout()).then {
      $0.backgroundColor = .white
      $0.showsVerticalScrollIndicator = false
      $0.keyboardDismissMode = .onDrag
    }

  init(reactor: PreviewReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    self.navigationController?.isNavigationBarHidden = true
    setUIConstraints()
    print("넘어온 데이터 : \(String(describing: self.reactor?.draft))")
  }

  // UI 설정
  private func setUIConstraints() {

    view.addSubview(headerView)

    headerView.addSubview(backButton)
    headerView.addSubview(titleLabel)
    view.addSubview(priviewCollectionView)
    view.addSubview(doneButton)

    headerView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(58)
    }

    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(20)
      $0.centerY.equalTo(headerView.snp.centerY)
    }

    priviewCollectionView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom)
      $0.leading.trailing.equalToSuperview()
      $0.bottom.equalTo(doneButton.snp.top)
    }

    doneButton.snp.makeConstraints {
      $0.bottom.equalTo(view).inset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }
  }

  func bind(reactor: PreviewReactor) {
    reactor.state
      .take(1) // 최초 1회만
      .bind { [weak self] state in
        guard let self else { return }
        applySnapshot(from: state) // 제목/이미지/설명/태그를 한 번에 세팅
      }
      .disposed(by: disposeBag)

    backButton.rx.tap
      .map { Reactor.Action.tapPop }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    doneButton.rx.tap
      .map { Reactor.Action.tapDismiss }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    reactor.state
      .map(\.tags)
      .distinctUntilChanged()
      .bind { [weak self] _ in
        guard let self else { return }
        applySnapshot(from: reactor.currentState)
      }
      .disposed(by: disposeBag)
  }

  private func createLayout() -> UICollectionViewCompositionalLayout {
    return UICollectionViewCompositionalLayout { sectionIndex, _ in
      switch sectionIndex {
      case 0:
        return self.titleSectionLayout()
      case 1:
        return self.thumbnailSectionLayout()
      case 2:
        return self.descriptionSectionLayout()
      case 3:
        return self.tagSectionLayout()
      default:
        return self.titleSectionLayout()
      }
    }
  }

  // 타이틀
  private func titleSectionLayout() -> NSCollectionLayoutSection {
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

  // 썸네일
  private func thumbnailSectionLayout() -> NSCollectionLayoutSection {
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

  // 요약
  private func descriptionSectionLayout() -> NSCollectionLayoutSection {
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

  // 태그
  private func tagSectionLayout() -> NSCollectionLayoutSection {
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
      widthDimension: .estimated(10),
      heightDimension: .absolute(42)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)

    let groupSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1.0),
      heightDimension: .estimated(52)
    )
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    group.interItemSpacing = .fixed(8)

    let section = NSCollectionLayoutSection(group: group)
    section.boundarySupplementaryItems = [header]
    section.interGroupSpacing = 8
    section.orthogonalScrollingBehavior = .none
    section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 20, bottom: 24, trailing: 20)
    return section
  }

  func applySnapshot(from state: PreviewReactor.State) {
    var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
    snapshot.appendSections([.title, .thumbnails, .description, .tags])

    // 제목
    snapshot.appendItems([.title(TitleItem(text: state.title))], toSection: .title)
    // 썸네일
    var thumbItems: [Item] = [.thumbnail(ThumbnailItem(kind: .addButton))]
    thumbItems += state.thumbnails.map { .thumbnail(ThumbnailItem(kind: .image($0))) }
    snapshot.appendItems(thumbItems, toSection: .thumbnails)
    // 요약
    snapshot.appendItems([.description(DescriptionItem(text: state.description))], toSection: .description)
    // 태그
    let tagItems: [Item] = state.tags.map { .tag(TagItem(tag: $0)) }
    snapshot.appendItems(tagItems, toSection: .tags)

    dataSource.apply(snapshot, animatingDifferences: true)
  }

  // swiftlint:disable cyclomatic_complexity
  private func setupDataSource(
    _ collectionView: UICollectionView
  ) -> UICollectionViewDiffableDataSource<Section, Item> {
    // 제목 셀 설정
    let titleRegistration = UICollectionView.CellRegistration<TitleCell, Item> { cell, _, item in
      guard case let .title(titleItem) = item else { return }
      cell.configure(text: titleItem.text)
    }

    // 썸네일 셀 설정
    let addRegistration = UICollectionView.CellRegistration<AddImageCell, Item> { _, _, _ in }
    let thumbRegistration = UICollectionView.CellRegistration<ThumbnailCell, Item> { cell, _, item in
      guard case let .thumbnail(thumbnailItem) = item else { return }
      switch thumbnailItem.kind {
      case .addButton:
        break
      case .image(let image):
        cell.configure(image: image)
      }
    }

    // 요약 셀 설정
    let descRegistration = UICollectionView.CellRegistration<DescriptionCell, Item> { cell, _, item in
      guard case let .description(descriptionItem) = item else { return }
      cell.configure(text: descriptionItem.text)
    }

    // 태그 셀 설정
    let tagRegistration = UICollectionView.CellRegistration<TagCell, Item> { [weak self] cell, _, item in
      guard let self, let reactor = self.reactor else { return }
      guard case let .tag(tagItem) = item else { return }
      cell.configure(text: tagItem.tag)

      cell.xMarker.rx.tap
        .map { PreviewReactor.Action.tapRemoveTag(tagItem.tag) }
        .bind(to: reactor.action)
        .disposed(by: cell.disposeBag)
    }

    // 데이터 소스 생성
    let dataSource = UICollectionViewDiffableDataSource<Section, Item>(
      collectionView: collectionView
    ) { collectionView, indexPath, item in
      let section = Section.allCases[indexPath.section]
      switch section {
      case .title:
        return collectionView.dequeueConfiguredReusableCell(using: titleRegistration, for: indexPath, item: item)
      case .thumbnails:
        if case .thumbnail(let thumbnailItem) = item, case .addButton = thumbnailItem.kind {
          return collectionView.dequeueConfiguredReusableCell(using: addRegistration, for: indexPath, item: item)
        } else {
          return collectionView.dequeueConfiguredReusableCell(using: thumbRegistration, for: indexPath, item: item)
        }
      case .description:
        return collectionView.dequeueConfiguredReusableCell(using: descRegistration, for: indexPath, item: item)
      case .tags:
        return collectionView.dequeueConfiguredReusableCell(using: tagRegistration, for: indexPath, item: item)
      }
    }

    // 섹션 헤더 등록
    let headerRegistration = UICollectionView.SupplementaryRegistration<HeaderView>(
      elementKind: UICollectionView.elementKindSectionHeader
    ) { [weak self] header, _, indexPath in
      guard let self, let reactor = self.reactor else { return }
      let section = Section.allCases[indexPath.section]
      header.configure(section: section)
      // 태그 섹션에서만 + 버튼 활성화
      guard section == .tags else { return }

      header.plusButton.rx.tap
        .map { PreviewReactor.Action.tapAddTag }
        .bind(to: reactor.action)
        .disposed(by: header.disposeBag)
    }

    dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
      guard kind == UICollectionView.elementKindSectionHeader else { return nil }
      return collectionView.dequeueConfiguredReusableSupplementary(
        using: headerRegistration,
        for: indexPath
      )
    }

    return dataSource
  }
  // swiftlint:enable cyclomatic_complexity
}

@available(iOS 17.0, *)
#Preview {
  let sampleDraft = PostDraft(
    title: "샘플 제목",
    content: NSAttributedString(string: "샘플 내용")
  )
  let reactor = PreviewReactor(draft: sampleDraft)
  return UINavigationController(rootViewController: PreviewViewController(reactor: reactor))
}

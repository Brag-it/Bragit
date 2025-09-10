//
//  PreviewViewController.swift
//  Bragit
//
//  Created by 이태윤 on 8/27/25.
//
import UIKit
import PhotosUI

import ReactorKit
import RxSwift
import RxCocoa

final class PreviewViewController: UIViewController, View {
  var disposeBag = DisposeBag()

  // 배경을 어둡게 하는 반투명 오버레이
  private let dimmingView = UIView().then {
    $0.backgroundColor = UIColor.black.withAlphaComponent(0.3)
    $0.isHidden = true
    $0.isUserInteractionEnabled = true // 터치 차단
  }

  private let activityIndicator = UIActivityIndicatorView(style: .large).then {
    $0.hidesWhenStopped = true
    $0.color = .primary400
  }

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
    view.backgroundColor = .white
    self.navigationController?.isNavigationBarHidden = true
    setUIConstraints()
    print("넘어온 데이터 : \(String(describing: self.reactor?.draft))")
  }

  // UI 설정
  private func setUIConstraints() {
    view.addSubview(dimmingView)
    view.addSubview(activityIndicator)

    view.addSubview(headerView)

    headerView.addSubview(backButton)
    headerView.addSubview(titleLabel)
    view.addSubview(priviewCollectionView)
    view.addSubview(doneButton)

    dimmingView.snp.makeConstraints {
      $0.directionalEdges.equalToSuperview()
    }

    activityIndicator.snp.makeConstraints {
      $0.center.equalToSuperview()
    }

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

    view.bringSubviewToFront(dimmingView)
    view.bringSubviewToFront(activityIndicator)
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
      .map { Reactor.Action.tapDone }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    priviewCollectionView.rx.itemSelected
      .compactMap { [weak self] indexPath in
        self?.dataSource.itemIdentifier(for: indexPath)
      }
      .bind { [weak self] item in
        guard let self else { return }
        // 썸네일추가 셀 이면 사진 추가 그게아니면 썸네일 사진 선택
        if case let .thumbnail(thumbnailItem) = item {
          switch thumbnailItem.kind {
          case .addButton:
            presentPhotoPicker()
          case .image(let image):
            reactor.action.onNext(.tapThumbnail(image))
          }
        }
      }
      .disposed(by: disposeBag)

    reactor.state
      .map { $0.thumbnails.count }
      .distinctUntilChanged()
      .bind { [weak self] _ in
        guard let self else { return }
        applySnapshot(from: reactor.currentState)
        scrollToFirstThumbnailIfNeeded()
      }
      .disposed(by: disposeBag)

    reactor.state
      .map(\.representativeImage)
      .distinctUntilChanged { $0 === $1 }
      .bind { [weak self] _ in
        guard let self else { return }
        reconfigureThumbnailsSelection()
      }
      .disposed(by: disposeBag)

    reactor.state
      .map(\.tags)
      .distinctUntilChanged()
      .bind { [weak self] _ in
        guard let self else { return }
        applySnapshot(from: reactor.currentState)
      }
      .disposed(by: disposeBag)

    reactor.state
      .map(\.isLoading)
      .distinctUntilChanged()
      .observe(on: MainScheduler.instance)
      .bind { [weak self] isLoading in
        guard let self else { return }

        // 디밍 on/off + 스피너 on/off
        if isLoading {
          self.dimmingView.isHidden = false
          self.dimmingView.alpha = 0
          self.view.bringSubviewToFront(self.dimmingView)
          self.view.bringSubviewToFront(self.activityIndicator)

          UIView.animate(withDuration: 0.2) { self.dimmingView.alpha = 1 }
          self.activityIndicator.startAnimating()
        } else {
          UIView.animate(withDuration: 0.2, animations: {
            self.dimmingView.alpha = 0
          }, completion: { _ in
            self.dimmingView.isHidden = true
          })
          self.activityIndicator.stopAnimating()
        }

        // 입력 막기 & 중복 탭 방지
        self.view.isUserInteractionEnabled = !isLoading
        self.doneButton.isEnabled = !isLoading
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
    var snapshot = NSDiffableDataSourceSnapshot<PreviewSection, Item>()
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
  ) -> UICollectionViewDiffableDataSource<PreviewSection, Item> {
    // 제목 셀 설정
    let titleRegistration = UICollectionView.CellRegistration<TitleCell, Item> { cell, _, item in
      guard case let .title(titleItem) = item else { return }
      cell.configure(text: titleItem.text)
    }

    // 썸네일 셀 설정
    let addRegistration = UICollectionView.CellRegistration<AddImageCell, Item> { _, _, _ in }
    let thumbRegistration = UICollectionView.CellRegistration<ThumbnailCell, Item> { [weak self] cell, _, item in
      guard let self, case let .thumbnail(thumbnailItem) = item else { return }
      switch thumbnailItem.kind {
      case .addButton:
        cell.updateSelection(isSelected: false)
      case .image(let image):
        cell.configure(image: image)
        let rep = self.reactor?.currentState.representativeImage
        let isSelected = (rep != nil && rep === image)
        cell.updateSelection(isSelected: isSelected)
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
    let dataSource = UICollectionViewDiffableDataSource<PreviewSection, Item>(
      collectionView: collectionView
    ) { collectionView, indexPath, item in
      let section = PreviewSection.allCases[indexPath.section]
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
      let section = PreviewSection.allCases[indexPath.section]
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

  private func presentPhotoPicker() {
    var config = PHPickerConfiguration(photoLibrary: .shared())
    config.selectionLimit = 1
    config.filter = .images
    let picker = PHPickerViewController(configuration: config)
    picker.delegate = self
    present(picker, animated: true)
  }

  // 이미지 추가후 처음 셀로 스크롤
  private func scrollToFirstThumbnailIfNeeded() {
    guard let thumbnailsSection = PreviewSection.allCases.firstIndex(of: .thumbnails) else { return }
    let items = priviewCollectionView.numberOfItems(inSection: thumbnailsSection)
    guard items > 1 else { return }
    let indexPath = IndexPath(item: 0, section: thumbnailsSection)

    priviewCollectionView.layoutIfNeeded()
    DispatchQueue.main.async { [weak self] in
      self?.priviewCollectionView.scrollToItem(at: indexPath, at: .left, animated: true)
    }
  }

  // 대표 이미지 선택 상태가 바뀔 때, 썸네일 섹션 아이템만 재구성해서 셀의 선택 표현을 업데이트
  private func reconfigureThumbnailsSelection() {
    var snapshot = dataSource.snapshot()
    guard snapshot.sectionIdentifiers.contains(.thumbnails) else { return }
    let thumbItems = snapshot.itemIdentifiers(inSection: .thumbnails)
    snapshot.reconfigureItems(thumbItems)
    dataSource.apply(snapshot, animatingDifferences: false)
  }
}

extension PreviewViewController: PHPickerViewControllerDelegate {
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)

    guard !results.isEmpty else { return }

    for result in results {
      let provider = result.itemProvider
      if provider.canLoadObject(ofClass: UIImage.self) {
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
          guard let self, let image = object as? UIImage else { return }
          self.reactor?.action.onNext(.appendThumbnail(image))
        }
      }
    }
  }
}

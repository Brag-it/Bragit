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

  private let titleTextField = UITextField().then {
    $0.placeholder = "제목을 입력해 주세요"
    $0.borderStyle = .none
    $0.textColor = .grayScale900
    $0.font = .pretendard(size: 20, weight: .semibold)
  }

  private let dividerView = UIView().then {
    $0.backgroundColor = .grayScale100
  }

  private let thumbnailTitle = UILabel().then {
    $0.text = "대표 이미지(썸네일)"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale600
  }

  private lazy var dataSource = setupDataSource(self.thumbnailCollectionView)

  private lazy var thumbnailCollectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout()).then {
    $0.backgroundColor = .white
    $0.showsVerticalScrollIndicator = false
    $0.keyboardDismissMode = .onDrag
  }

  private let decriptionTitle = UILabel().then {
    $0.text = "게시글 설명"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale600
  }

  private let descriptionLabel = DescriptionTextView().then {
    $0.placeholder = "내용을 잘 나타내는 설명을 입력해 주세요"
    $0.font = .pretendard(size: 15)
    $0.layer.cornerRadius = 14
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16) // 내부 여백
    $0.layer.borderWidth = 1
  }

  private let tagTitle = UILabel().then {
    $0.text = "태그 추가"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale600
  }

  private let tagAddButton = UIButton(type: .system).then {
    $0.setImage(.plus, for: .normal)
    $0.tintColor = .grayScale600
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
    view.addSubview(thumbnailCollectionView)
    view.addSubview(doneButton)

    //    view.addSubview(titleTextField)
    //    view.addSubview(dividerView)
    //    view.addSubview(thumbnailTitle)
    //    view.addSubview(decriptionTitle)
    //    view.addSubview(descriptionLabel)
    //    view.addSubview(tagTitle)
    //    view.addSubview(tagAddButton)

    headerView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(58)
    }

    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(20)
      $0.centerY.equalTo(headerView.snp.centerY)
    }

    //    titleLabel.snp.makeConstraints {
    //      $0.centerX.equalTo(headerView.snp.centerX)
    //      $0.centerY.equalTo(headerView.snp.centerY)
    //      $0.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(20)
    //    }
    //
    //   titleTextField.snp.makeConstraints {
    //      $0.top.equalTo(headerView.snp.bottom).offset(24)
    //      $0.leading.trailing.equalToSuperview().inset(20)
    //    }
    //
    //    dividerView.snp.makeConstraints {
    //      $0.top.equalTo(titleTextField.snp.bottom).offset(16)
    //      $0.leading.trailing.equalTo(titleTextField)
    //      $0.height.equalTo(1)
    //    }
    //
    //    thumbnailTitle.snp.makeConstraints {
    //      $0.top.equalTo(dividerView.snp.bottom).offset(24)
    //      $0.leading.trailing.equalTo(titleTextField)
    //    }

    thumbnailCollectionView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom).offset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.bottom.equalTo(doneButton.snp.top).offset(-24)
    }

    //    decriptionTitle.snp.makeConstraints {
    //      $0.top.equalTo(thumbnailCollectionView.snp.bottom).offset(24)
    //      $0.leading.trailing.equalToSuperview().inset(20)
    //    }
    //
    //    descriptionLabel.snp.makeConstraints {
    //      $0.top.equalTo(decriptionTitle.snp.bottom).offset(8)
    //      $0.leading.trailing.equalToSuperview().inset(20)
    //      $0.height.equalTo(128)
    //    }
    //
    //    tagTitle.snp.makeConstraints {
    //      $0.top.equalTo(descriptionLabel.snp.bottom).offset(44)
    //      $0.leading.equalToSuperview().inset(20)
    //    }
    //
    //    tagAddButton.snp.makeConstraints {
    //      $0.top.equalTo(tagTitle)
    //      $0.trailing.equalToSuperview().inset(20)
    //    }

    doneButton.snp.makeConstraints {
      $0.bottom.equalTo(view).inset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }
  }

  func bind(reactor: PreviewReactor) {
    backButton.rx.tap
      .map { Reactor.Action.tapPop }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    doneButton.rx.tap
      .map { Reactor.Action.tapDismiss }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 제목
    reactor.state
      .map(\.title)
      .bind(to: titleTextField.rx.text)
      .disposed(by: disposeBag)

    // 썸네일 (이미지가 있을 경우만)
    reactor.state
      .map(\.thumbnail)
      .distinctUntilChanged()
      .bind { [weak self] images in
        guard let self else { return }
        print("📸 바인딩된 이미지 수: \(images.count)")
        applySnapshot(with: images)
      }
      .disposed(by: disposeBag)

    // 미리보기 텍스트
    reactor.state
      .map(\.decription)
      .bind(to: descriptionLabel.rx.text)
      .disposed(by: disposeBag)
  }

  private func createLayout() -> UICollectionViewCompositionalLayout {
    return UICollectionViewCompositionalLayout { sectionIndex, environment in
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
    let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
    let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.8), heightDimension: .absolute(380))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    let section = NSCollectionLayoutSection(group: group)
    section.boundarySupplementaryItems = [header]
    section.orthogonalScrollingBehavior = .continuous
    section.interGroupSpacing = 16
    section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
    return section
  }
  // 타이틀
  private func thumbnailSectionLayout() -> NSCollectionLayoutSection {
    let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
    let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
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
    section.orthogonalScrollingBehavior = .groupPagingCentered
    section.interGroupSpacing = 8
    return section
  }
  // 타이틀
  private func descriptionSectionLayout() -> NSCollectionLayoutSection {
    let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
    let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.8), heightDimension: .absolute(380))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    let section = NSCollectionLayoutSection(group: group)
    section.boundarySupplementaryItems = [header]
    section.orthogonalScrollingBehavior = .groupPagingCentered
    section.interGroupSpacing = 16
    section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
    return section
  }
  // 타이틀
  private func tagSectionLayout() -> NSCollectionLayoutSection {
    let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
    let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.8), heightDimension: .absolute(380))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    let section = NSCollectionLayoutSection(group: group)
    section.boundarySupplementaryItems = [header]
    section.orthogonalScrollingBehavior = .groupPagingCentered
    section.interGroupSpacing = 16
    section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
    return section
  }

  func applySnapshot(with images: [UIImage]) {
    var snapshot = NSDiffableDataSourceSnapshot<Section, ThumbnailItem>()
    snapshot.appendSections([.thumbnails])
    snapshot.appendSections([.description])
    snapshot.appendSections([.tags])

    snapshot.appendItems([ThumbnailItem(type: .addButton)], toSection: .thumbnails)
    snapshot.appendItems(images.map { ThumbnailItem(type: .image($0)) }, toSection: .thumbnails)
    dataSource.apply(snapshot, animatingDifferences: true)
  }

  private func setupDataSource(
    _ collectionView: UICollectionView
  ) -> UICollectionViewDiffableDataSource<Section, ThumbnailItem> {
    //Add 버튼 셀
    let addCellRegistration = UICollectionView.CellRegistration<AddImageCell, ThumbnailItem> { _, _, _ in
    }
    // 일반 셀 설정
    let imageCellRegistration = UICollectionView.CellRegistration<ThumbnailCell, ThumbnailItem> { cell, _, item in
      if case let .image(image) = item.type {
        cell.configure(image: image)
      }
    }

    // 데이터 소스 생성
    let dataSource = UICollectionViewDiffableDataSource<Section, ThumbnailItem>(
      collectionView: collectionView
    ) { collectionView, indexPath, item in
      switch item.type {
      case .addButton:
        return collectionView.dequeueConfiguredReusableCell(
          using: addCellRegistration,
          for: indexPath,
          item: item
        )
      case .image:
        return collectionView.dequeueConfiguredReusableCell(
          using: imageCellRegistration,
          for: indexPath,
          item: item
        )
      }
    }

    return dataSource
  }
}

extension PreviewViewController {
  enum Section: CaseIterable {
    case title
    case thumbnails
    case description
    case tags

    // 헤더 타이틀
    var headerTitle: String {
      switch self {
      case .title: return ""
      case .thumbnails: return "대표 이미지(썸네일)"
      case .description: return "게시글 설명"
      case .tags: return "태그 추가"
      }
    }
  }

  enum Item: Hashable {
    case thumbnail(ThumbnailItem)     // 썸네일
    case description(DescriptionItem) // 설명
    case tag(TagItem)                 // 태그
  }

  struct ThumbnailItem: Hashable {
    enum ItemType: Hashable {
      case addButton            // 고정 추가 버튼 셀
      case image(UIImage)       // 썸네일 이미지 셀
    }

    let id: UUID = UUID()
    let type: ItemType
    var isSelected: Bool = false

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: ThumbnailItem, rhs: ThumbnailItem) -> Bool { lhs.id == rhs.id }
  }

  struct DescriptionItem: Hashable {
    let id: UUID = UUID()
    var text: String
  }

  struct TagItem: Hashable {
    let id: UUID = UUID()
    var title: String
    var isDeletable: Bool = true
  }
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

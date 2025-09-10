//
//  TagCheckViewController.swift
//  Bragit
//
//  Created by luca on 8/27/25.
//

import UIKit

import Dependencies
import RxCocoa
import RxSwift
import SnapKit
import Then

typealias PopularTag = Tag

class TagCheckViewController: UIViewController {
  private let disposeBag = DisposeBag()
  @Dependency(\.tagManager) private var tagManager
  private var tags: [PopularTag] = []

  @LocalStorage(location: .favoriteTags) private var favoriteTags: [Tag]?
  private let userInfo: UserRegistrationInfo
  private let injectReactor: TagCheckReactor
  var reactor: TagCheckReactor?

  let descFont = UIFont.pretendard(size: 20, weight: .semibold)
  let beLaterFont = UIFont.pretendard(size: 16, weight: .regular)
  let nextFont = UIFont.pretendard(size: 16, weight: .medium)

  let primaryColor = UIColor(named: "primary400")
  let color900 = UIColor(named: "grayScale900")
  let color700 = UIColor(named: "grayScale700")

  // MARK: UI
  lazy var mainDescriptionLabel = UILabel().then {
    $0.text = "관심 있는 주제를 선택해 보세요"
    $0.font = descFont
    $0.textColor = color900
  }

  lazy var subDescriptionLabel = UILabel().then {
    $0.text = "해당 태그가 포함된 글들만 모아볼 수 있어요"
    $0.font = beLaterFont
    $0.textColor = color700
  }

  lazy var tagCollectionView: UICollectionView = {
    let layout = makeCollectionViewLayout()
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .clear
    collectionView.allowsMultipleSelection = true
    collectionView.showsVerticalScrollIndicator = false
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.register(TagButtonCell.self, forCellWithReuseIdentifier: TagButtonCell.identifier)
    return collectionView
  }()

  lazy var beLaterButton = UIButton().then {
    $0.setTitle("건너뛰기", for: .normal)
    $0.titleLabel?.font = beLaterFont
    $0.setTitleColor(color700, for: .normal)
    $0.backgroundColor = nil
  }

  lazy var nextButton = UIButton().then {
    $0.setTitle("확인", for: .normal)
    $0.setTitleColor(color900, for: .normal)
    $0.titleLabel?.font = nextFont
    $0.layer.cornerRadius = 12
    $0.backgroundColor = primaryColor
  }

  init(userInfo: UserRegistrationInfo, reactor: TagCheckReactor) {
    self.userInfo = userInfo
    self.injectReactor = reactor
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // 가입할 때 태그 있으면 안 되니 아예 초기화
    self.favoriteTags = []

    view.backgroundColor = .white
    title = "회원가입"
    setupLayout()
    loadTags()

    self.reactor = injectReactor
    bind(reactor: injectReactor)
  }

  private func setupLayout() {
    [
      mainDescriptionLabel,
      subDescriptionLabel,
      tagCollectionView,
      beLaterButton,
      nextButton
    ].forEach {
      view.addSubview($0)
    }

    mainDescriptionLabel.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    subDescriptionLabel.snp.makeConstraints {
      $0.top.equalTo(mainDescriptionLabel.snp.bottom).offset(8)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    tagCollectionView.snp.makeConstraints {
      $0.top.equalTo(subDescriptionLabel.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)

      $0.bottom.equalTo(beLaterButton.snp.top).offset(-16)
    }

    beLaterButton.snp.makeConstraints {
      //      $0.bottom.equalTo(nextButton.snp.top).inset(8)
      $0.bottom.equalTo(nextButton.snp.top).offset(-8)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }

    nextButton.snp.makeConstraints {
      $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }
  }

  func bind(reactor: TagCheckReactor) {
    beLaterButton.rx.tap
      .map {
        TagCheckReactor.Action.tapLater
      }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    nextButton.rx.tap
      .withUnretained(self)
      .map { owner, _ in
        let selectedIndexPaths = owner.tagCollectionView.indexPathsForSelectedItems ?? []
        let chosenModels: [Tag] =
          selectedIndexPaths
          .sorted { $0.item < $1.item }
          .map { owner.tags[$0.item] }
        owner.favoriteTags = chosenModels

        print("[Local.favoriteTags(models)] -> \(chosenModels.map { $0.tag })")

        return TagCheckReactor.Action.tapNext(tags: chosenModels)
      }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    reactor.state.compactMap { $0.errorMessage }
      .observe(on: MainScheduler.instance)
      .bind { [weak self] message in
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "확인", style: .default))
        self?.present(alert, animated: true)
      }
      .disposed(by: disposeBag)

    // isLoading 스트림
    let loading = reactor.state
      .map { $0.isLoading }
      .distinctUntilChanged()
      .share(replay: 1)

    // 토글마다 업데이트
    let selectionChanged = Observable.merge(
      tagCollectionView.rx.itemSelected.map { _ in () },
      tagCollectionView.rx.itemDeselected.map { _ in () }
    )
    .startWith(())
    .share(replay: 1)

    let hasSelection = selectionChanged
      .map { [weak self] in
        guard let self else { return false }
        let isEmpty = self.tagCollectionView.indexPathsForSelectedItems?.isEmpty ?? true
        return !isEmpty
      }
      .distinctUntilChanged()
      .share(replay: 1)

    loading
      .bind { [weak self] isLoading in
        self?.view.isUserInteractionEnabled = !isLoading
      }
      .disposed(by: disposeBag)

    // 선택된 게 있을 때 nextButton 활성, 로딩 중엔 비활성
    Observable.combineLatest(hasSelection, loading)
      .map { has, isLoading in has && !isLoading }
      .bind(to: nextButton.rx.isEnabled)
      .disposed(by: disposeBag)

    Observable.combineLatest(hasSelection, loading)
      .map { has, isLoading in (has && !isLoading) ? 1.0 : 0.5 }
      .bind { [weak self] alpha in self?.nextButton.alpha = alpha }
      .disposed(by: disposeBag)

    // 선택된 게 없을 때 beLaterButton 활성, 로딩 중엔 비활성
    Observable.combineLatest(hasSelection, loading)
      .map { has, isLoading in !has && !isLoading }
      .bind(to: beLaterButton.rx.isEnabled)
      .disposed(by: disposeBag)

    Observable.combineLatest(hasSelection, loading)
      .map { has, isLoading in (!has && !isLoading) ? 1.0 : 0.5 }
      .bind { [weak self] alpha in self?.beLaterButton.alpha = alpha }
      .disposed(by: disposeBag)
  }

  private func debugPrintFavoriteTagsFromUserDefaults() {
    if let decoded = favoriteTags {
      print("[Local.favoriteTags] -> \(decoded.map { $0.tag })")
    } else {
      print("[Local.favoriteTags] -> []")
    }
  }

  private func loadTags() {
    tagManager.rxFetchPopularTags()
      .observe(on: MainScheduler.instance)
      .subscribe(
        onNext: { [weak self] tags in
          guard let self else { return }
          self.tags = tags
          self.tagCollectionView.reloadData()
          if let selectedTags = self.favoriteTags?.map({$0.tag}), !selectedTags.isEmpty {
            for (idx, tag) in self.tags.enumerated() where selectedTags.contains(tag.tag) {
              let indexPath = IndexPath(item: idx, section: 0)
              self.tagCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            }
            self.tagCollectionView.reloadData()
          }
          self.applyButtonStateAccordingToSelection()
        },
        onError: { error in
          print("[ERROR] 태그 로딩 에러: \(error)")
        }
      )
      .disposed(by: disposeBag)
  }

  private func applyButtonStateAccordingToSelection() {
    let hasSelection = (tagCollectionView.indexPathsForSelectedItems?.isEmpty == false)
    let isLoading = reactor?.currentState.isLoading ?? false
    nextButton.isEnabled = hasSelection && !isLoading
    nextButton.alpha = nextButton.isEnabled ? 1.0 : 0.5
    beLaterButton.isEnabled = !hasSelection && !isLoading
    beLaterButton.alpha = beLaterButton.isEnabled ? 1.0 : 0.5
  }

  private func printFavoriteTags(from collectionView: UICollectionView) {
    let selectedIndexPaths = collectionView.indexPathsForSelectedItems ?? []
    let chosen =
      selectedIndexPaths
      .sorted { $0.item < $1.item }
      .map { self.tags[$0.item].tag }
    print("[favoriteTags] -> \(chosen)")
  }
}

extension TagCheckViewController: UICollectionViewDelegate,
  UICollectionViewDataSource {
  func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    return tags.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    guard
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: TagButtonCell.identifier,
        for: indexPath
      )
        as? TagButtonCell
    else { return UICollectionViewCell() }
    let tag = tags[indexPath.item]
    cell.configure(with: tag)
    cell.isSelected = collectionView.indexPathsForSelectedItems?.contains(indexPath) == true
    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) { printFavoriteTags(from: collectionView) }

  func collectionView(
    _ collectionView: UICollectionView,
    didDeselectItemAt indexPath: IndexPath
  ) { printFavoriteTags(from: collectionView) }
}

class TagButtonCell: UICollectionViewCell {
  static let identifier = "TagButtonCell"
  private let containerView = UIView()
  private let titleLabel = UILabel()

  override var isSelected: Bool {
    didSet { updateStyle() }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupHierarchy()
    setupLayout()
    setupUI()
    updateStyle()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupHierarchy() {
    contentView.addSubview(containerView)
    containerView.addSubview(titleLabel)
  }

  private func setupLayout() {
    containerView.snp.makeConstraints { $0.edges.equalToSuperview() }
    titleLabel.snp.makeConstraints {
      $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14))
    }
  }

  private func setupUI() {
    containerView.layer.borderWidth = 1
    containerView.layer.cornerRadius = 21
    containerView.layer.masksToBounds = true

    titleLabel.textAlignment = .center
    titleLabel.font = UIFont.pretendard(size: 15, weight: .medium)
    titleLabel.numberOfLines = 1
    titleLabel.lineBreakMode = .byTruncatingTail
    titleLabel.setContentHuggingPriority(.required, for: .horizontal)
    titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
  }

  private func updateStyle() {
    if isSelected {
      containerView.backgroundColor = .primary100
      containerView.layer.borderColor = UIColor.primary100.cgColor
      titleLabel.textColor = .grayScale900
    } else {
      containerView.backgroundColor = .white
      containerView.layer.borderColor = UIColor.grayScale100.cgColor
      titleLabel.textColor = .grayScale600
    }
  }

  func configure(with tag: PopularTag) { titleLabel.text = tag.tag }
}

private func makeCollectionViewLayout() -> UICollectionViewCompositionalLayout {
  let layoutItem = NSCollectionLayoutItem(
    layoutSize: NSCollectionLayoutSize(
      widthDimension: .estimated(42),
      heightDimension: .absolute(42)
    )
  )
  let layoutGroup = NSCollectionLayoutGroup.horizontal(
    layoutSize: NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .absolute(42)
    ),
    subitems: [layoutItem]
  )
  layoutGroup.interItemSpacing = .fixed(8)

  let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
  layoutSection.interGroupSpacing = 10
  layoutSection.contentInsetsReference = .none
  return UICollectionViewCompositionalLayout(section: layoutSection)
}

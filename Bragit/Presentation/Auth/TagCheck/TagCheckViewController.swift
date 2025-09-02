//
//  TagCheckViewController.swift
//  Bragit
//
//  Created by luca on 8/27/25.
//

import Dependencies
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

typealias PopularTag = Tag

class TagCheckViewController: UIViewController {
  private let disposeBag = DisposeBag()
  @Dependency(\.tagManager) private var tagManager
  private var tags: [PopularTag] = []
  private var selectedTags: Set<String> = []

  private let userInfo: UserRegistrationInfo
  private let injectReactor: TagCheckReactor
  var reactor: TagCheckReactor?

  // MARK: UI
  let mainDescriptionLabel = UILabel().then {
    $0.text = "관심 있는 주제를 선택해 보세요"
  }

  let subDescriptionLabel = UILabel().then {
    $0.text = "해당 태그가 포함된 글들만 모아볼 수 있어요"
  }

  lazy var tagCollectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = 8
    layout.minimumLineSpacing = 10
    layout.scrollDirection = .vertical
    layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = .clear
    collectionView.showsVerticalScrollIndicator = false
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.register(TagButtonCell.self, forCellWithReuseIdentifier: TagButtonCell.identifier)
    return collectionView
  }()

  let beLaterButton = UIButton().then {
    $0.setTitle("건너뛰기", for: .normal)
  }

  let nextButton = UIButton().then {
    $0.setTitle("확인", for: .normal)
    $0.setTitleColor(UIColor(red: 0.315, green: 0.315, blue: 0.315, alpha: 1), for: .normal)
    $0.layer.cornerRadius = 12
    $0.backgroundColor = .orange
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
    view.backgroundColor = .systemBackground
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
      //      .map { TagCheckReactor.Action.tapNext }
      .withUnretained(self)
      .map { owner, _ in
        TagCheckReactor.Action.tapNext(tags: Array(owner.selectedTags))
      }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    reactor.state
      .map(\.isLoading)
      .distinctUntilChanged()
      .bind(with: self) { owner, loading in
        owner.view.isUserInteractionEnabled = !loading
        if !loading {
          owner.updateNextButtonState()
        }
      }
      .disposed(by: disposeBag)
  }

  private func loadTags() {
    tagManager.rxFetchPopularTags()
      .observe(on: MainScheduler.instance)
      .subscribe(
        onNext: { [weak self] tags in
          self?.tags = tags
          //          self?.tags = tags as! [PopularTag]
          self?.tagCollectionView.reloadData()
        },
        onError: { error in
          print("[ERROR] 태그 로딩 에러: \(error)")
        }
      )
      .disposed(by: disposeBag)
  }

  private func updateNextButtonState() {
    let hasSelection = !selectedTags.isEmpty
    nextButton.isEnabled = hasSelection
    UIView.animate(withDuration: 0.3) {
      self.nextButton.alpha = hasSelection ? 1.0 : 0.5
    }
  }
}

extension TagCheckViewController: UICollectionViewDelegate, UICollectionViewDataSource,
  UICollectionViewDelegateFlowLayout
{
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return tags.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagButtonCell.identifier, for: indexPath)
        as? TagButtonCell
    else {
      return UICollectionViewCell()
    }
    let tag = tags[indexPath.item]
    let isSelected = selectedTags.contains(tag.tag)
    cell.configure(with: tag, isSelected: isSelected)

    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
//    return CGSize(width: 80, height: 80)
    let tag = tags[indexPath.item]
    let label = UILabel()
    label.text = tag.tag
    label.sizeToFit()
    let width = label.frame.width + 28
    let height = label.frame.height + 16
    return CGSize(width: width, height: height)
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let tag = tags[indexPath.item]

    if selectedTags.contains(tag.tag) {
      selectedTags.remove(tag.tag)
    } else {
      selectedTags.insert(tag.tag)
    }

    collectionView.reloadItems(at: [indexPath])
    updateNextButtonState()
  }
}

class TagButtonCell: UICollectionViewCell {
  static let identifier = "TagButtonCell"

  private let tagButton = UIButton().then {
    // $0.layer.cornerRadius = 80
    $0.layer.borderWidth = 1
    $0.titleLabel?.textAlignment = .center
    $0.titleLabel?.lineBreakMode = .byWordWrapping
    $0.isUserInteractionEnabled = false

    var config = UIButton.Configuration.plain()
    config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
    config.cornerStyle = .capsule
    $0.configuration = config
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupLayout()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupLayout() {
    contentView.addSubview(tagButton)
    tagButton.snp.makeConstraints {
      $0.edges.equalToSuperview()
      // $0.width.height.equalTo(80)
    }
  }

  func configure(with tag: PopularTag, isSelected: Bool) {
    tagButton.setTitle(tag.tag, for: .normal)

    if isSelected {
      tagButton.backgroundColor = .orange
    } else {
      tagButton.backgroundColor = .gray
    }
  }
}

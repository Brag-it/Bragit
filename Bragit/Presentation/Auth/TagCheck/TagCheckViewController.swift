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
  var favoriteTags: [String] = []

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
    let layout = LeftAlignedFlowLayout()
    //    layout.minimumInteritemSpacing = 8
    //    layout.minimumLineSpacing = 10
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
    view.backgroundColor = .systemBackground
    title = "회원가입"
    setupLayout()
    loadTags()

    if let data = UserDefaults.standard.data(forKey: "favoriteTags"),
      let decoded = try? JSONDecoder().decode([String].self, from: data)
    {
      self.favoriteTags = decoded
      self.selectedTags = Set(decoded)
    }
    self.selectedTags = Set(favoriteTags)
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
  }

  private func loadTags() {
    tagManager.rxFetchPopularTags()
      .observe(on: MainScheduler.instance)
      .subscribe(
        onNext: { [weak self] tags in
          self?.tags = tags
          //          self?.tags = tags as! [PopularTag]
          self?.selectedTags = Set(self?.favoriteTags ?? [])
          self?.tagCollectionView.reloadData()
        },
        onError: { error in
          print("[ERROR] 태그 로딩 에러: \(error)")
        }
      )
      .disposed(by: disposeBag)
  }
}

extension TagCheckViewController: UICollectionViewDelegate, UICollectionViewDataSource,
  UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    return tags.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagButtonCell.identifier, for: indexPath)
        as? TagButtonCell
    else { return UICollectionViewCell() }
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
    let tag = tags[indexPath.item]
    let font = UIFont.preferredFont(forTextStyle: .body)
    let text = tag.tag as NSString
    let max = CGSize(
      width: CGFloat.greatestFiniteMagnitude,
      height: CGFloat.greatestFiniteMagnitude
    )
    let rect = text.boundingRect(
      with: max,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: font],
      context: nil
    )
    let width = ceil(rect.width) + 28
    let height = ceil(rect.height) + 16
    return CGSize(width: width, height: height)
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let tag = tags[indexPath.item]

    if selectedTags.contains(tag.tag) {
      selectedTags.remove(tag.tag)
    } else {
      selectedTags.insert(tag.tag)
    }

    self.favoriteTags = Array(self.selectedTags).sorted()
    if let data = try? JSONEncoder().encode(self.favoriteTags) {
      UserDefaults.standard.set(data, forKey: "favoriteTags")
    }
    print("[favoriteTags] -> \(self.favoriteTags)")
    collectionView.reloadItems(at: [indexPath])
  }
}

class TagButtonCell: UICollectionViewCell {
  static let identifier = "TagButtonCell"

  private let tagButton = UIButton().then {
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
    }
  }

  func configure(with tag: PopularTag, isSelected: Bool) {
    let tagFont = UIFont.pretendard(size: 15, weight: .medium)

    let enableColor = UIColor(named: "primary100")
    let enableFontColor = UIColor(named: "grayScale900")
    let disableBorder = UIColor(named: "grayScale100")

    let disableFontColor = UIColor(named: "grayScale600")

    tagButton.setTitle(tag.tag, for: .normal)
    tagButton.titleLabel?.font = tagFont

    if isSelected {
      tagButton.backgroundColor = enableColor
      tagButton.layer.borderColor = enableColor?.cgColor
      tagButton.setTitleColor(enableFontColor, for: .normal)
    } else {
      tagButton.backgroundColor = nil
      tagButton.layer.borderColor = disableBorder?.cgColor
      tagButton.setTitleColor(disableFontColor, for: .normal)
    }
  }
}

final class LeftAlignedFlowLayout: UICollectionViewFlowLayout {
  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    guard
      let attributes = super.layoutAttributesForElements(in: rect)?.map({
        $0.copy() as! UICollectionViewLayoutAttributes
      })
    else { return nil }

    guard scrollDirection == .vertical,
      let collectionView = collectionView
    else { return attributes }

    let contentWidth =
      collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right
    let sectionInsets = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset ?? .zero
    let inter = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumInteritemSpacing ?? 8

    var left = sectionInsets.left
    var lastY: CGFloat = -CGFloat.greatestFiniteMagnitude

    for attr in attributes where attr.representedElementCategory == .cell {
      if attr.frame.origin.y >= lastY + attr.frame.height / 2 {
        left = sectionInsets.left
        lastY = attr.frame.origin.y
      }

      var frame = attr.frame
      if frame.width > contentWidth - sectionInsets.left - sectionInsets.right {
        frame.size.width = contentWidth - sectionInsets.left - sectionInsets.right
      }
      frame.origin.x = left
      attr.frame = frame.integral

      left = frame.maxX + inter
      if left + frame.width > contentWidth - sectionInsets.right {
        left = sectionInsets.left
        lastY = frame.maxY + minimumLineSpacing
      }
    }
    return attributes
  }

  override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { true }
}

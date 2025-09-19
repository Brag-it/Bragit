//
//  SignupTagSelectView.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import UIKit

import SnapKit
import Then

typealias PopularTag = Tag
final class SignupTagSelectView: UIView {
  var tags: [PopularTag] = []

  private let headerView = UIView()
  let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }
  private let headerLabel = UILabel().then {
    $0.text = "회원가입"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
  }

  // MARK: UI 컴포넌트 정의

  private let descriptionTitleLabel = UILabel().then {
    $0.text = "관심 있는 주제를 선택해 보세요"
    $0.numberOfLines = 2
    $0.lineBreakMode = .byWordWrapping
    $0.setContentHuggingPriority(.required, for: .vertical)
    $0.setContentCompressionResistancePriority(.required, for: .vertical)
    $0.font = .pretendard(size: 20, weight: .semibold)
    $0.textColor = .grayScale900
  }

  private let descriptionLabel = UILabel().then {
    $0.text = "해당 태그가 포함된 글들만 모아볼 수 있어요"
    $0.font = .pretendard(size: 20, weight: .semibold)
    $0.textColor = .grayScale900
  }

  lazy var tagCollectionView: UICollectionView = {
    let layout = makeCollectionViewLayout()
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout).then {
      $0.backgroundColor = .clear
      $0.allowsMultipleSelection = true
      $0.showsVerticalScrollIndicator = false
      $0.delegate = self
      $0.dataSource = self
      $0.register(SignupTagButtonCell.self, forCellWithReuseIdentifier: SignupTagButtonCell.identifier)
    }
    return collectionView
  }()

  lazy var beLaterButton = UIButton().then {
    $0.setTitle("건너뛰기", for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16, weight: .regular)
    $0.setTitleColor(.grayScale700, for: .normal)
    $0.backgroundColor = nil
  }

  lazy var nextButton = UIButton().then {
    $0.setTitle("확인", for: .normal)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16, weight: .medium)
    $0.layer.cornerRadius = 12
    $0.backgroundColor = .primary400
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    headerUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func headerUI() {
    addSubview(headerView)
    [backButton, headerLabel].forEach { headerView.addSubview($0) }

    headerView.snp.makeConstraints {
      $0.top.equalTo(safeAreaLayoutGuide.snp.top)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(58)
    }

    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(20)
      $0.centerY.equalTo(headerView.snp.centerY)
    }

    headerLabel.snp.makeConstraints {
      $0.centerX.equalTo(headerView.snp.centerX)
      $0.centerY.equalTo(headerView.snp.centerY)
      $0.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(20)
    }

    configureUI()
  }

  private func configureUI() {
    [
      descriptionTitleLabel,
      descriptionLabel,
      tagCollectionView,
      beLaterButton,
      nextButton,
    ].forEach { addSubview($0) }

    descriptionTitleLabel.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    descriptionLabel.snp.makeConstraints {
      $0.top.equalTo(descriptionTitleLabel.snp.bottom).offset(8)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    tagCollectionView.snp.makeConstraints {
      $0.top.equalTo(descriptionLabel.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.bottom.equalTo(beLaterButton.snp.top).offset(-16)
    }

    beLaterButton.snp.makeConstraints {
      $0.bottom.equalTo(nextButton.snp.top).offset(-8)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }

    nextButton.snp.makeConstraints {
      $0.bottom.equalTo(safeAreaLayoutGuide).inset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }
  }

  private func printFavoriteTags(from collectionView: UICollectionView) {
    let selectedIndexPaths = collectionView.indexPathsForSelectedItems ?? []
    let chosen = selectedIndexPaths.sorted { $0.item < $1.item }
      .map { self.tags[$0.item].tag }
    print("[favoriteTags] -> \(chosen)")
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
}

extension SignupTagSelectView: UICollectionViewDelegate, UICollectionViewDataSource {
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
        withReuseIdentifier: SignupTagButtonCell.identifier,
        for: indexPath
      ) as? SignupTagButtonCell
    else { return UICollectionViewCell() }
    let tag = tags[indexPath.item]
    cell.configure(with: tag)
    cell.isSelected = collectionView.indexPathsForSelectedItems?.contains(indexPath) == true
    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    printFavoriteTags(from: collectionView)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    didDeselectItemAt indexPath: IndexPath
  ) {
    printFavoriteTags(from: collectionView)
  }
}

private class SignupTagButtonCell: UICollectionViewCell {
  static let identifier = "SignupTagButtonCell"
  private let containerView = UIView()
  private let headerLabel = UILabel()

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
    containerView.addSubview(headerLabel)
  }

  private func setupLayout() {
    containerView.snp.makeConstraints { $0.edges.equalToSuperview() }
    headerLabel.snp.makeConstraints {
      $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14))
    }
  }

  private func setupUI() {
    containerView.layer.borderWidth = 1
    containerView.layer.cornerRadius = 21
    containerView.layer.masksToBounds = true

    headerLabel.textAlignment = .center
    headerLabel.font = UIFont.pretendard(size: 15, weight: .medium)
    headerLabel.numberOfLines = 1
    headerLabel.lineBreakMode = .byTruncatingTail
    headerLabel.setContentHuggingPriority(.required, for: .horizontal)
    headerLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
  }

  private func updateStyle() {
    if isSelected {
      containerView.backgroundColor = .primary100
      containerView.layer.borderColor = UIColor.primary100.cgColor
      headerLabel.textColor = .grayScale900
    } else {
      containerView.backgroundColor = .white
      containerView.layer.borderColor = UIColor.grayScale100.cgColor
      headerLabel.textColor = .grayScale600
    }
  }

  func configure(with tag: PopularTag) { headerLabel.text = tag.tag }
}

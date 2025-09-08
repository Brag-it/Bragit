//
//  SearchHeaderView.swift
//  Bragit
//
//  Created by 이태윤 on 9/8/25.
//
import UIKit

import SnapKit
import Then
import RxSwift
import RxCocoa

final class SearchHeaderView: UICollectionReusableView {
  static let identifier = "SearchHeaderView"
  enum Tab: Int { case tag = 0, post = 1, user = 2 }

  // 외부 바인딩용 선택된 탭
  let selected = BehaviorRelay<Tab>(value: .tag)

  var disposeBag = DisposeBag()

  private let tagButton = UIButton(type: .system).then {
    $0.setTitle("태그", for: .normal)
    $0.titleLabel?.font = .pretendard(size: 15, weight: .medium)
  }
  private let postButton = UIButton(type: .system).then {
    $0.setTitle("게시글", for: .normal)
    $0.titleLabel?.font = .pretendard(size: 15, weight: .medium)
  }
  private let userButton = UIButton(type: .system).then {
    $0.setTitle("사용자", for: .normal)
    $0.titleLabel?.font = .pretendard(size: 15, weight: .medium)
  }

  private let indicator = UIView().then {
    $0.backgroundColor = .primary400
    $0.layer.cornerRadius = 1
  }

  private lazy var buttons: [UIButton] = [tagButton, postButton, userButton]

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
    bind()
    applyStyle(for: .tag, animated: false)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  // MARK: - UI
  private func setupUI() {
    backgroundColor = .white

    let stack = UIStackView(arrangedSubviews: buttons).then {
      $0.axis = .horizontal
      $0.alignment = .center
      $0.distribution = .fillEqually
    }

    addSubview(stack)
    addSubview(indicator)

    stack.snp.makeConstraints {
      $0.top.equalToSuperview()
      $0.leading.trailing.equalToSuperview().inset(10)
      $0.height.equalTo(49)
    }

    indicator.snp.makeConstraints {
      $0.top.equalTo(stack.snp.bottom)
      $0.height.equalTo(2)
      $0.leading.trailing.equalTo(tagButton)
      $0.bottom.equalToSuperview()
    }
  }

  // MARK: - Bind
  private func bind() {
    tagButton.rx.tap
      .map { Tab.tag }
    .bind(to: selected)
    .disposed(by: disposeBag)

    postButton.rx.tap
      .map { Tab.post }
      .bind(to: selected)
      .disposed(by: disposeBag)

    userButton.rx.tap
      .map { Tab.user }
      .bind(to: selected)
      .disposed(by: disposeBag)

    selected
      .distinctUntilChanged()
      .bind { [weak self] tab in
        guard let self else { return }
        applyStyle(for: tab, animated: true)
      }
      .disposed(by: disposeBag)
  }

  private func applyStyle(for tab: Tab, animated: Bool) {
    for (index, button) in buttons.enumerated() {
      let isSelected = index == tab.rawValue
      button.setTitleColor(isSelected ? .grayScale900 : .grayScale600, for: .normal)
      button.titleLabel?.font = .pretendard(size: 15, weight: isSelected ? .medium : .regular)
    }

    let targetButton = buttons[tab.rawValue]
    guard let container = targetButton.superview else { return }

    indicator.snp.remakeConstraints {
      $0.top.equalTo(container.snp.bottom)
      $0.height.equalTo(2)
      $0.leading.trailing.equalTo(targetButton)
      $0.bottom.equalToSuperview()
    }

    if animated {
      UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseInOut) {
        self.layoutIfNeeded()
      }
    } else {
      layoutIfNeeded()
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
  }
}

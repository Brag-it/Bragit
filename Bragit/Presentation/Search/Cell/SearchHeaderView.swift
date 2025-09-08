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

final class SearchHeaderView: UIView {

  enum Tab: Int { case tag = 0, post = 1, user = 2 }

  private var current: Tab = .tag

  let tagButton = UIButton(type: .system).then {
    $0.setTitle("태그", for: .normal)
    $0.titleLabel?.font = .pretendard(size: 15, weight: .medium)
  }
  let postButton = UIButton(type: .system).then {
    $0.setTitle("게시글", for: .normal)
    $0.titleLabel?.font = .pretendard(size: 15, weight: .medium)
  }
  let userButton = UIButton(type: .system).then {
    $0.setTitle("사용자", for: .normal)
    $0.titleLabel?.font = .pretendard(size: 15, weight: .medium)
  }

  let indicator = UIView().then {
    $0.backgroundColor = .primary400
    $0.layer.cornerRadius = 1
  }

  lazy var buttons: [UIButton] = [tagButton, postButton, userButton]

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
    applyStyle(for: .tag, animated: false)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

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

  // 현재 선택된 탭
  var currentTab: Tab { current }

  // 탭에 해당하는 버튼 반환
  func button(for tab: Tab) -> UIButton {
    switch tab {
    case .tag: return tagButton
    case .post: return postButton
    case .user: return userButton
    }
  }

  func set(tab: Tab, animated: Bool) {
    guard current != tab else { return }
    current = tab
    applyStyle(for: tab, animated: animated)
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
}

//
//  TagsView.swift
//  Bragit
//
//  Created by seongjun cho on 8/24/25.
//

import UIKit

import Then

final class TagsView: UIView {

  private var buttons: [UIButton] = []
  private let horizontalSpacing: CGFloat = 7.0
  private let verticalSpacing: CGFloat = 7.0

  override func layoutSubviews() {
    super.layoutSubviews()

    var currentX: CGFloat = 0
    var currentY: CGFloat = 0
    var lineHeight: CGFloat = 0

    for button in buttons {
      let buttonSize = button.intrinsicContentSize
      let buttonWidth = buttonSize.width
      let buttonHeight = buttonSize.height

      if currentX + buttonWidth > bounds.width {
        currentX = 0
        currentY += lineHeight + verticalSpacing
        lineHeight = 0
      }

      button.frame = CGRect(x: currentX, y: currentY, width: buttonWidth, height: buttonHeight)

      currentX += buttonWidth + horizontalSpacing
      lineHeight = max(lineHeight, buttonHeight)
    }
  }

  override var intrinsicContentSize: CGSize {
    var currentX: CGFloat = 0
    var currentY: CGFloat = 0
    var lineHeight: CGFloat = 0

    // 너비가 0일 때를 대비해, 화면 너비에서 셀의 여백(좌우 20씩)을 뺀 값을 예상 너비로 사용
    let calculationWidth = bounds.width > 0 ? bounds.width : (UIScreen.main.bounds.width - 40)

    buttons.forEach { button in
      let buttonSize = button.intrinsicContentSize
      let buttonWidth = buttonSize.width
      let buttonHeight = buttonSize.height

      if currentX + buttonWidth > calculationWidth {
        currentX = 0
        currentY += lineHeight + verticalSpacing
        lineHeight = 0
      }

      currentX += buttonWidth + horizontalSpacing
      lineHeight = max(lineHeight, buttonHeight)
    }

    let totalHeight = buttons.isEmpty ? 0 : currentY + lineHeight
    return CGSize(width: UIView.noIntrinsicMetric, height: totalHeight)
  }

  func configure(with tags: [Tag]) {
    clearTags()

    let viewWidth = bounds.width > 0 ? bounds.width : (UIScreen.main.bounds.width - 40)
    var currentX: CGFloat = 0
    var currentY: CGFloat = 0
    var lineHeight: CGFloat = 0
    let maxHeight: CGFloat = 75.0
    @LocalStorage(location: LocalStorageCase.favoriteTags) var favoriteTags: [Tag]?

    for tag in tags {
      let tagButton = makeTagButton(tag: tag, favoriteTags: favoriteTags)
      let buttonSize = tagButton.intrinsicContentSize
      let buttonWidth = buttonSize.width
      let buttonHeight = buttonSize.height

      if currentX + buttonWidth + horizontalSpacing > viewWidth {
        currentX = 0
        currentY += lineHeight + verticalSpacing
        lineHeight = 0
      }

      if currentY + buttonHeight >= maxHeight {
        break
      }

      self.buttons.append(tagButton)
      self.addSubview(tagButton)

      currentX += buttonWidth + horizontalSpacing
      lineHeight = max(lineHeight, buttonHeight)
    }

    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }

  func clearTags() {
    buttons.forEach { $0.removeFromSuperview() }
    buttons.removeAll()
    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }

  private func makeTagButton(tag: Tag, favoriteTags: [Tag]?) -> UIButton {
    let tagButton = UIButton().then {
      var configuration = UIButton.Configuration.filled()

      configuration.title = tag.tag
      configuration.attributedTitle?.font = .pretendard(size: 14)
      configuration.baseForegroundColor = .grayScale600
      configuration.baseBackgroundColor = .white
      configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
      configuration.cornerStyle = .capsule
      configuration.titleLineBreakMode = .byTruncatingTail
      configuration.background.strokeColor = .grayScale100
      configuration.background.strokeWidth = 1.0
      let tagIDs = favoriteTags.map { $0.map(\.id) }
      if favoriteTags != nil && tagIDs?.firstIndex(of: tag.id) != nil {
        configuration.background.strokeColor = .grayScale700
        configuration.baseForegroundColor = .grayScale700
      }

      $0.configuration = configuration
    }
    return tagButton
  }
}

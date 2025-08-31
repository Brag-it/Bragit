//
//  DescriptionTextView.swift
//  Bragit
//
//  Created by 이태윤 on 9/1/25.
//
import UIKit

import Then
import SnapKit
final class DescriptionTextView: UITextView {

  private let placeholderLabel = UILabel()

  var placeholder: String? {
    didSet {
      placeholderLabel.text = placeholder
      setNeedsLayout()
      updatePlaceholderVisibility()
    }
  }

  var placeholderColor: UIColor = .grayScale400 {
    didSet {
      placeholderLabel.textColor = placeholderColor
    }
  }

  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    delegate = self
    backgroundColor = .white

    placeholderLabel.font = self.font
    placeholderLabel.textColor = placeholderColor
    placeholderLabel.numberOfLines = 0
    placeholderLabel.isUserInteractionEnabled = false
    addSubview(placeholderLabel)
    updatePlaceholderVisibility()
  }

  private func setupPlaceholder() {
    addSubview(placeholderLabel)
    placeholderLabel.isHidden = !text.isEmpty
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    // 커서 기준 위치와 placeholder 위치를 맞추기
    let padding = textContainer.lineFragmentPadding
    let inset = textContainerInset

    let x = inset.left + padding
    let y = inset.top
    let maxWidth = bounds.width - inset.left - inset.right - 2 * padding
    let maxHeight = bounds.height - inset.top - inset.bottom

    placeholderLabel.frame = CGRect(x: x, y: y, width: maxWidth, height: 0)
    placeholderLabel.sizeToFit()

    if placeholderLabel.frame.height > maxHeight {
      placeholderLabel.frame.size.height = maxHeight
    }
    updatePlaceholderVisibility()
  }

  private func updatePlaceholderVisibility() {
    placeholderLabel.isHidden = !text.isEmpty
  }
}

extension DescriptionTextView: UITextViewDelegate {
  func textViewDidChange(_ textView: UITextView) {
    updatePlaceholderVisibility()
  }

  func textViewDidBeginEditing(_ textView: UITextView) {
    updatePlaceholderVisibility()
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    updatePlaceholderVisibility()
  }
}

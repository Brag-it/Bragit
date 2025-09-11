//
//  RichTextViewWithPlaceholder.swift
//  Bragit
//
//  Created by 이태윤 on 9/9/25.
//
import UIKit

import Then
import RichTextKit

final class RichTextViewWithPlaceholder: RichTextView {

  private let placeholderLabel = UILabel().then {
    $0.font = .pretendard(size: 16)
  }

  var placeholder: String? {
    didSet {
      placeholderLabel.text = placeholder
      updatePlaceholderVisibility()
    }
  }

  var placeholderColor: UIColor = .grayScale400 {
    didSet {
      placeholderLabel.textColor = placeholderColor
    }
  }

  override var text: String! {
    didSet {
      updatePlaceholderVisibility()
    }
  }

  override var attributedText: NSAttributedString! {
    didSet {
      updatePlaceholderVisibility()
    }
  }

  override init(frame: CGRect, textContainer: NSTextContainer?) {
    super.init(frame: frame, textContainer: textContainer)
    configurePlaceholder()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    configurePlaceholder()
  }

  private func configurePlaceholder() {
    delegate = self
    placeholderLabel.textColor = placeholderColor
    placeholderLabel.numberOfLines = 0
    placeholderLabel.isUserInteractionEnabled = false
    addSubview(placeholderLabel)
  }

  override func layoutSubviews() {
    super.layoutSubviews()

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

extension RichTextViewWithPlaceholder: UITextViewDelegate {
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

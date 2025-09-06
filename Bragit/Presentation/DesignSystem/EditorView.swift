//
//  EditorView.swift
//  Bragit
//
//  Created by 이태윤 on 8/27/27.
//
import UIKit

import SnapKit
import Then
import RxSwift
import RxCocoa
import RichTextKit

final class EditorView: UIView {
  let accessoryView = EditorAccessoryView()

  lazy var textView = RichTextView().then {
    $0.typingAttributes[.font] = UIFont.systemFont(ofSize: 16)
    $0.backgroundColor = .systemBackground
    $0.isEditable = true
    $0.isScrollEnabled = true
    $0.showsVerticalScrollIndicator = false
    $0.autocorrectionType = .no
    $0.smartDashesType = .no
    $0.smartQuotesType = .no
    $0.textDragInteraction?.isEnabled = true
    $0.inputAccessoryView = accessoryView
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupLayout()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupLayout() {
    self.addSubview(textView)
    textView.snp.makeConstraints {
      $0.directionalEdges.equalToSuperview()
    }
  }

  func applyBold(_ isOn: Bool) {
    setStyle(.bold, enabled: isOn)
  }

  func applyUnderline(_ isOn: Bool) {
    setStyle(.underlined, enabled: isOn)
  }

  func applyStrikethrough(_ isOn: Bool) {
    setStyle(.strikethrough, enabled: isOn)
  }

  private func setStyle(_ style: RichTextStyle, enabled: Bool) {
    let has = textView.hasRichTextStyle(style) // 현재 스타일 적용 여부 확인
    if has != enabled {
      textView.toggleRichTextStyle(style)
    }
  }

  func insertImage(image: UIImage) {
    // 이미지 첨부(Attachment) 객체를 생성
    let attachment = NSTextAttachment()
    attachment.image = image

    // 이미지의 크기를 에디터의 폭에 맞게 조절
    let screenWidth = self.bounds.width
    let padding: CGFloat = 16 // 에디터의 좌우 여백을 고려
    let imageWidth = screenWidth - padding
    let aspectRatio = image.size.height / image.size.width
    let imageHeight = imageWidth * aspectRatio
    attachment.bounds = CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)

    // Attachment를 NSAttributedString으로 변환
    let imageAttributedString = NSAttributedString(attachment: attachment)

    // 현재 커서 위치에 이미지 AttributedString을 삽입
    let textStorage = textView.textStorage
    let insertionIndex = textView.selectedRange.location
    textStorage.insert(imageAttributedString, at: insertionIndex)

    // 이미지 다음에 기본 스타일의 공백 삽입
    let defaultAttributes = textView.typingAttributes
    let spacer = NSAttributedString(string: " ", attributes: defaultAttributes)
    textStorage.insert(spacer, at: insertionIndex + 1)

    // 줄바꿈 추가
    textStorage.insert(NSAttributedString(string: "\n", attributes: defaultAttributes), at: insertionIndex + 2)

    // 커서를 이미지 다음 줄로 이동
    textView.selectedRange = NSRange(location: insertionIndex + 3, length: 0)
  }
}

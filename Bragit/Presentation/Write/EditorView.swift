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
    $0.font = .systemFont(ofSize: 16) // 현재 프리텐다드의 이탤릭 폰트가 없어 일단 systemFont적용
    $0.backgroundColor = .systemBackground
    $0.isEditable = true
    $0.isScrollEnabled = true
    $0.showsVerticalScrollIndicator = false
    $0.keyboardDismissMode = .onDrag
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
    setStyle(.bold, enabled: isOn) // 라이브러리 스타일 토글 사용
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
      textView.toggleRichTextStyle(style) // 필요할 때만 토글
    }
  }

  func insertImage(image: UIImage) {
    // 이미지 첨부(Attachment) 객체를 생성
    let attachment = NSTextAttachment()
    attachment.image = image

    // 이미지의 크기를 에디터의 폭에 맞게 조절
    let screenWidth = self.bounds.width
    let padding: CGFloat = 16 // 에디터의 좌우 여백을 고려
    let imageWidth = max(0, screenWidth - padding)
    let aspectRatio = image.size.height / max(image.size.width, 1) // 0 나누기 방지
    let imageHeight = imageWidth * aspectRatio
    attachment.bounds = CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)

    // Attachment를 NSAttributedString으로 변환
    let imageAttr = NSAttributedString(attachment: attachment)
    // 현재 커서 위치에 이미지 AttributedString을 삽입
    let textStorage = textView.textStorage

    let insertLocation = min(textView.selectedRange.location, textStorage.length)
    textStorage.beginEditing()
    textStorage.insert(imageAttr, at: insertLocation)
    // 이미지 삽입 후 커서를 이미지 다음으로 이동시키고, 줄바꿈을 추가하여 이미지 바로 뒤에 텍스트가 붙지 않도록
    textStorage.insert(NSAttributedString(string: "\n"), at: insertLocation + 1)
    textStorage.endEditing()

    // 커서를 줄바꿈 뒤로 이동
    textView.selectedRange = NSRange(location: insertLocation + 2, length: 0)
  }
}

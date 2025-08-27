//
//  TestMarkDownEditorView.swift
//  Bragit
//
//  Created by 이태윤 on 8/27/27.
//
import UIKit

import SnapKit
import Then
import RxSwift
import RxCocoa

final class TestMarkDownEditorView: UIView {
  private let accessoryView = EditorAccessoryView()

  private lazy var textView = UITextView().then {
    $0.font = .pretendard(size: 16)
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

  public var boldButtonTap: Observable<Void> {
    return accessoryView.boldButtonTap
  }

  public var imageButtonTap: Observable<Void> {
    return accessoryView.imageButtonTap
  }

  // textView의 rx 속성에 접근하기 위해 public으로 선언
  public var coreTextView: UITextView {
    return self.textView
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

  // 앞으로 입력될 텍스트의 속성을 토글(적용/해제)
  public func toggleTypingAttribute(fontTrait: UIFontDescriptor.SymbolicTraits) {
    var currentAttributes = textView.typingAttributes
    let currentFont = currentAttributes[.font] as? UIFont ?? textView.font ?? .systemFont(ofSize: 16)
    let newFont = currentFont.toggled(trait: fontTrait)
    currentAttributes[.font] = newFont
    textView.typingAttributes = currentAttributes
  }

  // 선택된 영역의 텍스트 속성을 토글(적용/해제)
  public func toggleSelectionAttribute(fontTrait: UIFontDescriptor.SymbolicTraits) {
    let range = textView.selectedRange
    guard range.length > 0 else { return } // 선택된 영역이 있을 때만 실행합니다.
    let textStorage = textView.textStorage
    var isAlreadyApplied = true
    textStorage.enumerateAttribute(.font, in: range) { (font, _, stop) in
      guard let font = font as? UIFont else {
        isAlreadyApplied = false
        stop.pointee = true
        return
      }
      if !font.fontDescriptor.symbolicTraits.contains(fontTrait) {
        isAlreadyApplied = false
        stop.pointee = true
      }
    }

    textStorage.beginEditing()
    textStorage.enumerateAttribute(.font, in: range) { (font, subrange, _) in
      let currentFont = font as? UIFont ?? textView.font ?? .systemFont(ofSize: 16)
      let newFont = isAlreadyApplied ? currentFont.removed(trait: fontTrait) : currentFont.toggled(trait: fontTrait)
      textStorage.addAttribute(.font, value: newFont, range: subrange)
    }
    textStorage.endEditing()
  }

  public func insertImage(image: UIImage) {
    // 이미지 첨부(Attachment) 객체를 생성합니다.
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
    textStorage.insert(imageAttributedString, at: textView.selectedRange.location)

    // 이미지 삽입 후 커서를 이미지 다음으로 이동시키고, 줄바꿈을 추가하여 이미지 바로 뒤에 텍스트가 붙지 않도록
    let newPosition = textView.selectedRange.location + 1
    textView.selectedRange = NSRange(location: newPosition, length: 0)
    textStorage.insert(NSAttributedString(string: "\n"), at: newPosition)
  }
}

// UIFont의 특정 특성(trait)을 쉽게 추가하거나 제거하기 위한 헬퍼
extension UIFont {
  // 주어진 특성을 현재 폰트에 토글(있으면 제거, 없으면 추가)하는 새 폰트를 반환
  func toggled(trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
    let descriptor = fontDescriptor
    var traits = descriptor.symbolicTraits

    if traits.contains(trait) {
      traits.remove(trait)
    } else {
      traits.insert(trait)
    }

    guard let newDescriptor = descriptor.withSymbolicTraits(traits) else {
      return self
    }
    // size 0은 기존 폰트 크기를 그대로 사용하라는 의미
    return UIFont(descriptor: newDescriptor, size: 0)
  }

  // 주어진 특성을 현재 폰트에서 제거하는 새 폰트를 반환
  func removed(trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
    let descriptor = fontDescriptor
    var traits = descriptor.symbolicTraits
    traits.remove(trait)
    guard let newDescriptor = descriptor.withSymbolicTraits(traits) else {
      return self
    }
    return UIFont(descriptor: newDescriptor, size: 0)
  }
}

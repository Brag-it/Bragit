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

  lazy var textView = RichTextViewWithPlaceholder().then {
    $0.placeholder = "오늘의 자랑을 자유롭게 나눠보세요 :)\n욕설, 혐오 등 타인에게 불쾌감을 주는 내용은 삭제될 수 있어요."
    $0.typingAttributes[.font] = UIFont.pretendard(size: 16)
    $0.backgroundColor = .white
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

  // 제목, 머리말 토글
  private func headingFont(level: Int) -> UIFont {
    switch level {
    case 1: return UIFont.pretendard(size: 22, weight: .bold)       // 제목
    default: return UIFont.pretendard(size: 20, weight: .semibold)  // 머리말
    }
  }

  private func bodyFont() -> UIFont {
    UIFont.pretendard(size: 16, weight: .regular)                   // 본문
  }

  // 헤더 스타일을 토글합니다.
  // - 선택 영역에 적용/해제하고, `typingAttributes`도 함께 바꿔서 이후 타이핑이 같은 스타일을 상속하게 함.
  func toggleHeading(level: Int) {
    let textView = textView
    let textStorage = textView.textStorage
    let sel = textView.selectedRange

    let hFont = headingFont(level: level)
    let bFont = bodyFont()

    // ▼ 안전 가드: 선택 위치가 범위를 벗어나면 커서 상속만 처리
    let loc = sel.location
    let length = textStorage.length
    let hasText = length > 0
    let safeLoc = hasText ? min(loc, max(0, length - 1)) : 0

    // 현재 위치의 폰트를 구함 (문서가 비어있으면 typingAttributes의 폰트로 판단)
    let currentFont: UIFont? = {
      if hasText, safeLoc < length,
      let font = textStorage.attribute(.font, at: safeLoc, effectiveRange: nil) as? UIFont {
        return font
      }
      return textView.typingAttributes[.font] as? UIFont
    }()

    // 같으면 해제, 다르면 적용
    let isSameHeading: Bool = {
      guard let font = currentFont else { return false }
      return font.fontName == hFont.fontName && abs(font.pointSize - hFont.pointSize) < 0.1
    }()

    if isSameHeading {
      // 이미 해당 헤더면 본문으로 해제
      if sel.length > 0 {
        textStorage.addAttributes([.font: bFont], range: sel) // 선택 영역 본문화
      }
      var attrs = textView.typingAttributes                 // 이후 타이핑도 본문 폰트 상속
      attrs[.font] = bFont
      textView.typingAttributes = attrs
    } else {
      // 해당 헤더가 아니면 → 헤더 적용
      if sel.length > 0 {
        textStorage.addAttributes([.font: hFont], range: sel)  // 선택 영역 헤더 적용
      }
      var attrs = textView.typingAttributes                 // 이후 타이핑도 헤더 폰트 상속
      attrs[.font] = hFont
      textView.typingAttributes = attrs
    }
  }

  private func setStyle(_ style: RichTextStyle, enabled: Bool) {
    let has = textView.hasRichTextStyle(style) // 현재 스타일 적용 여부 확인
    if has != enabled {
      textView.toggleRichTextStyle(style)
    }
  }

  func insertImage(image: UIImage) {
    // 본문 이미지는 1280
    let maxDimension: CGFloat = 1280
    let resizedImage = image.resized(in: CGSize(width: maxDimension, height: maxDimension)) ?? image

    let attachment = NSTextAttachment()
    attachment.image = resizedImage

    // 에디터 폭에 맞게 크기 조절
    let screenWidth = self.bounds.width
    let padding: CGFloat = 16
    let imageWidth = screenWidth - padding
    let aspectRatio = resizedImage.size.height / resizedImage.size.width
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

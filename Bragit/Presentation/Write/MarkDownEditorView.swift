////
////  MarkDownEditorView.swift
////  Bragit
////
////  Created by 이태윤 on 8/27/25.
////
//import UIKit
//
//import SnapKit
//import Then
//import RxSwift
//import RxCocoa
//
//final class MarkdownEditorView: UIView {
//  private let disposeBag = DisposeBag()
//  private let accessoryView = MarkdownAccessoryView()
//
//  private var rawText: String = ""
//  private var indexMap: [Int] = []
//
//  lazy var textView = UITextView().then {
//    $0.font = .pretendard(size: 16)
//    $0.backgroundColor = .systemBackground
//    $0.isEditable = true
//    $0.isScrollEnabled = true
//    $0.showsVerticalScrollIndicator = false
//    $0.keyboardDismissMode = .onDrag
//    $0.autocorrectionType = .no
//    $0.smartDashesType = .no
//    $0.smartQuotesType = .no
//    $0.textDragInteraction?.isEnabled = true
//    $0.inputAccessoryView = accessoryView
//  }
//
//  override init(frame: CGRect) {
//    super.init(frame: frame)
//    setupLayout()
//    textView.delegate = self
//    setupMarkdownButtons()
//    applyMarkdownStyle()
//  }
//
//  required init?(coder: NSCoder) {
//    fatalError("init(coder:) has not been implemented")
//  }
//
//  private func setupLayout() {
//    self.addSubview(textView)
//
//    textView.snp.makeConstraints {
//      $0.directionalEdges.equalToSuperview()
//    }
//  }
//
//  private func setupMarkdownButtons() {
//    accessoryView.boldButton.rx.tap
//      .bind { [weak self] in
//        self?.wrapSelectedText(prefix: "**", suffix: "**")
//      }
//      .disposed(by: disposeBag)
//
//    accessoryView.italicButton.rx.tap
//      .bind { [weak self] in
//        self?.wrapSelectedText(prefix: "_", suffix: "_")
//      }
//      .disposed(by: disposeBag)
//
//    accessoryView.headerButton.rx.tap
//      .bind { [weak self] in
//        self?.insertAtLineStart(prefix: "# ")
//      }
//      .disposed(by: disposeBag)
//
//    accessoryView.bulletButton.rx.tap
//      .bind { [weak self] in
//        self?.insertAtLineStart(prefix: "- ")
//      }
//      .disposed(by: disposeBag)
//  }
//  // 선택된 텍스트를 마크다운 문법으로 감싸는 함수
//  private func wrapSelectedText(prefix: String, suffix: String) {
//    guard let textRange = textView.selectedTextRange else { return }
//
//    if let selectedRange = textView.selectedTextRange, selectedRange.isEmpty {
//      // 선택된 텍스트가 없으면, prefix와 suffix를 삽입하고 커서를 그 사이로 이동
//      let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
//      let insertionText = "\(prefix)\(suffix)"
//      if let range = textView.selectedRange as NSRange? {
//        replaceRawText(range: range, with: insertionText)
//        applyMarkdownStyle()
//        DispatchQueue.main.async {
//          self.textView.selectedRange = NSRange(location: cursorPosition + prefix.count, length: 0)
//        }
//      }
//    } else {
//      // 선택된 텍스트를 감쌈
//      let selectedText = textView.text(in: textRange) ?? ""
//      let wrapped = "\(prefix)\(selectedText)\(suffix)"
//      if let range = textView.selectedRange as NSRange? {
//        replaceRawText(range: range, with: wrapped)
//        applyMarkdownStyle()
//        DispatchQueue.main.async {
//          let newCursorLocation = range.location + wrapped.count
//          self.textView.selectedRange = NSRange(location: newCursorLocation, length: 0)
//        }
//      }
//    }
//  }
//
//  private func replaceRawText(range: NSRange, with newText: String) {
//    guard range.location + range.length <= indexMap.count else { return }
//
//    let start = indexMap[range.location]
//    let end = indexMap[range.location + range.length]
//    let startIndex = rawText.index(rawText.startIndex, offsetBy: start)
//    let endIndex = rawText.index(rawText.startIndex, offsetBy: end)
//    rawText.replaceSubrange(startIndex..<endIndex, with: newText)
//  }
//
//  // 현재 줄 앞에 prefix 삽입 (ex. "# ", "- ")
//  private func insertAtLineStart(prefix: String) {
//    let selectedRange = textView.selectedRange
//
//    // indexMap을 사용해 뷰의 커서 위치를 rawText의 커서 위치로 변환
//    guard selectedRange.location < indexMap.count else { return }
//    let rawCursorLocation = indexMap[selectedRange.location]
//
//    // rawText에서 커서를 포함하는 줄의 범위를 찾음
//    guard let cursorIndex = rawText.index(rawText.startIndex,
//                                          offsetBy: rawCursorLocation,
//                                          limitedBy: rawText.endIndex) else { return }
//    let lineRange = rawText.lineRange(for: cursorIndex..<cursorIndex)
//
//    // 현재 줄이 이미 prefix로 시작하는지 확인
//    let currentLine = rawText[lineRange]
//    guard !currentLine.hasPrefix(prefix) else { return }
//
//    // rawText에서 해당 줄의 시작 부분에 prefix를 삽입
//    rawText.insert(contentsOf: prefix, at: lineRange.lowerBound)
//
//    // 뷰를 다시 렌더링
//    applyMarkdownStyle()
//
//    // 텍스트 뷰의 커서 위치를 업데이트
//    DispatchQueue.main.async {
//      let newCursorPosition = selectedRange.location + prefix.count
//      self.textView.selectedRange = NSRange(location: newCursorPosition, length: 0)
//    }
//  }
//
//  private func applyMarkdownStyle() {
//    let result = render(sourceText: rawText)
//    textView.attributedText = result.text
//    indexMap = result.map
//  }
//
//  private func render(sourceText: String) -> (text: NSAttributedString, map: [Int]) {
//    let attributedString = NSMutableAttributedString()
//    var map: [Int] = []
//    let headerFont = UIFont.pretendard(size: 24, weight: .bold)
//    let boldFont = UIFont.pretendard(size: 16, weight: .bold)
//    let italicFont = UIFont.italicSystemFont(ofSize: 16)
//    let normalFont = UIFont.pretendard(size: 16)
//    let textColor = UIColor.label
//    let normalAttributes: [NSAttributedString.Key: Any] = [.font: normalFont, .foregroundColor: textColor]
//    let headerAttributes: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: textColor]
//    let boldAttributes: [NSAttributedString.Key: Any] = [.font: boldFont, .foregroundColor: textColor]
//    let italicAttributes: [NSAttributedString.Key: Any] = [.font: italicFont, .foregroundColor: textColor]
//    let paragraphStyle = NSMutableParagraphStyle()
//    paragraphStyle.headIndent = 15
//    let listAttributes: [NSAttributedString.Key: Any] = [.font: normalFont,
//                                                         .foregroundColor: textColor, .paragraphStyle: paragraphStyle]
//    var lastIndex = sourceText.startIndex
//
//    do {
//      let pattern = "^#\\s(.*)|(^-{1,}\\s.*)|\\*\\*(.*?)\\*\\*|_(.*?)_"
//      let regex = try NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
//      let matches = regex.matches(in: sourceText, options: [], range: NSRange(sourceText.startIndex..., in: sourceText))
//
//      for match in matches {
//        guard let fullRange = Range(match.range, in: sourceText) else { continue }
//
//        // 일반 텍스트 구간
//        let prefixRange = lastIndex..<fullRange.lowerBound
//        let prefixString = String(sourceText[prefixRange])
//        attributedString.append(NSAttributedString(string: prefixString, attributes: normalAttributes))
//        for i in sourceText.distance(
//          from: sourceText.startIndex, to: prefixRange.lowerBound)..<sourceText.distance(
//            from: sourceText.startIndex, to: prefixRange.upperBound) {
//          map.append(i)
//        }
//
//        // 스타일링 처리 (토큰 제외)
//        if match.range(at: 1).location != NSNotFound, let headerRange = Range(match.range(at: 1), in: sourceText) {
//          // It's a header
//          let headerContent = String(sourceText[headerRange])
//          attributedString.append(NSAttributedString(string: headerContent, attributes: headerAttributes))
//          // Update map for the header content
//          for i in sourceText.distance(
//            from: sourceText.startIndex, to: headerRange.lowerBound)..<sourceText.distance(
//              from: sourceText.startIndex, to: headerRange.upperBound) {
//            map.append(i)
//          }
//        } else if match.range(at: 2).location != NSNotFound,
//                  let listLineRange = Range(match.range(at: 2), in: sourceText) {
//          let listLineContent = String(sourceText[listLineRange])
//          let content = String(listLineContent.dropFirst(2)) // drop "- "
//          let renderedListLine = "•\t" + content
//          attributedString.append(NSAttributedString(string: renderedListLine, attributes: listAttributes))
//          map.append(sourceText.distance(from: sourceText.startIndex, to: listLineRange.lowerBound))
//          map.append(sourceText.distance(from: sourceText.startIndex, to: listLineRange.lowerBound) + 1)
//          let contentStartIndex = sourceText.index(listLineRange.lowerBound, offsetBy: 2)
//          for i in sourceText.distance(
//            from: sourceText.startIndex, to: contentStartIndex)..<sourceText.distance(
//              from: sourceText.startIndex, to: listLineRange.upperBound) {
//            map.append(i)
//          }
//        } else if match.range(at: 3).location != NSNotFound,
//                  let boldTextRange = Range(match.range(at: 3), in: sourceText) {
//          let boldString = String(sourceText[boldTextRange])
//          attributedString.append(NSAttributedString(string: boldString, attributes: boldAttributes))
//          for i in sourceText.distance(
//            from: sourceText.startIndex, to: boldTextRange.lowerBound)..<sourceText.distance(
//              from: sourceText.startIndex, to: boldTextRange.upperBound) {
//            map.append(i)
//          }
//        } else if match.range(at: 4).location != NSNotFound,
//                  let italicTextRange = Range(match.range(at: 4), in: sourceText) {
//          let italicString = String(sourceText[italicTextRange])
//          attributedString.append(NSAttributedString(string: italicString, attributes: italicAttributes))
//          for i in sourceText.distance(
//            from: sourceText.startIndex, to: italicTextRange.lowerBound)..<sourceText.distance(
//              from: sourceText.startIndex, to: italicTextRange.upperBound) {
//            map.append(i)
//          }
//        }
//
//        lastIndex = fullRange.upperBound
//      }
//    } catch {}
//
//    // 마지막 남은 텍스트 추가
//    let suffixRange = lastIndex..<sourceText.endIndex
//    let suffixString = String(sourceText[suffixRange])
//    attributedString.append(NSAttributedString(string: suffixString, attributes: normalAttributes))
//    for i in sourceText.distance(
//      from: sourceText.startIndex, to: suffixRange.lowerBound)..<sourceText.distance(
//        from: sourceText.startIndex, to: suffixRange.upperBound) {
//      map.append(i)
//    }
//    map.append(sourceText.count)
//    return (attributedString, map)
//  }
//}
//
//extension MarkdownEditorView: UITextViewDelegate {
//  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//    // 현재 rawText와 indexMap을 기반으로 변경될 범위를 찾습니다.
//    let rawStart: Int
//    if range.location < indexMap.count {
//      rawStart = indexMap[range.location]
//    } else {
//      rawStart = rawText.count
//    }
//
//    let rawEnd: Int
//    if range.location + range.length < indexMap.count {
//      rawEnd = indexMap[range.location + range.length]
//    } else {
//      rawEnd = rawText.count
//    }
//
//    guard let startIndex = rawText.index(rawText.startIndex, offsetBy: rawStart, limitedBy: rawText.endIndex),
//          let endIndex = rawText.index(rawText.startIndex, offsetBy: rawEnd, limitedBy: rawText.endIndex) else {
//      return false
//    }
//
//    // rawText를 업데이트합니다.
//    rawText.replaceSubrange(startIndex..<endIndex, with: text)
//
//    // 변경된 rawText로 뷰를 다시 렌더링합니다.
//    applyMarkdownStyle()
//
//    // 렌더링 후, 새로운 텍스트와 매핑 테이블을 기반으로 커서 위치를 업데이트합니다.
//    // 비동기적으로 처리하여 'shouldChangeTextIn'이 반환된 후 UI 업데이트가 이루어지도록 합니다.
//    DispatchQueue.main.async {
//      let newCursorPosition = range.location + text.count
//      self.textView.selectedRange = NSRange(location: newCursorPosition, length: 0)
//    }
//
//    // UITextView가 자체적으로 텍스트를 변경하는 것을 막습니다.
//    // 모든 변경은 applyMarkdownStyle()을 통해 이루어집니다.
//    return false
//  }
//}

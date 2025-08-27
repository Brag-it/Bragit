//
//  MarkDownEditorView.swift
//  Bragit
//
//  Created by 이태윤 on 8/27/25.
//
import UIKit

import SnapKit
import Then
import RxSwift
import RxCocoa

final class MarkdownEditorView: UIView {
  // 텍스트의 시각적 스타일과 레이아웃을 담당하는 TextKit2의 핵심 렌더링 매니저
  let layoutManager = NSTextLayoutManager()
  // 텍스트 데이터를 저장하는 객체
  let contentStorage = NSTextContentStorage()
  // 텍스트가 배치될 위치와 영역을 정의하는 컨테이너
  let textContainer = NSTextContainer()
  private let disposeBag = DisposeBag()

  lazy var textView = UITextView(frame: .zero, textContainer: self.textContainer).then {
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
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupTextKit2()
    setupLayout()
    setupTextBinding()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupTextKit2() {
    contentStorage.addTextLayoutManager(layoutManager)
    layoutManager.textContainer = textContainer
  }

  private func setupLayout() {
    self.addSubview(textView)

    textView.snp.makeConstraints {
      $0.directionalEdges.equalToSuperview()
    }
  }

  private func setupTextBinding() {
    textView.rx.text.orEmpty
      .distinctUntilChanged()
      .debounce(.milliseconds(80), scheduler: MainScheduler.instance)
      .subscribe { [weak self] _ in
        self?.applyMarkdownStyle()
      }
      .disposed(by: disposeBag)
  }

  private func applyMarkdownStyle() {
    // 현재 입력된 텍스트
    guard let text = textView.text else { return }

    // 스타일 적용을 위한 NSMutableAttributedString 생성
    let attributed = NSMutableAttributedString(string: text)
    let fullRange = NSRange(location: 0, length: attributed.length)

    // 기본 폰트와 색상 초기화
    attributed.addAttribute(.font, value: UIFont.pretendard(size: 16), range: fullRange)
    attributed.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)
    // 볼드 처리
    let boldPattern = "\\*\\*(.*?)\\*\\*"
    if let regex = try? NSRegularExpression(pattern: boldPattern) {
      regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
        guard let match = match else { return }
        let boldRange = match.range(at: 1) // 굵게 처리할 실제 텍스트 영역

        attributed.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: boldRange)

        // ** 기호 숨기기
        let prefixRange = NSRange(location: match.range.location, length: 2)
        let suffixRange = NSRange(location: match.range.location + match.range.length - 2, length: 2)
        attributed.addAttribute(.foregroundColor, value: UIColor.clear, range: prefixRange)
        attributed.addAttribute(.foregroundColor, value: UIColor.clear, range: suffixRange)
      }
    }
    // 이탤릭 처리
    let italicPattern = "\\_(.*?)\\_"
    if let regex = try? NSRegularExpression(pattern: italicPattern) {
      regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
        guard let match = match else { return }
        let italicRange = match.range(at: 1)

        attributed.addAttribute(.font, value: UIFont.italicSystemFont(ofSize: 16), range: italicRange)

        // _ 기호 숨기기
        let prefixRange = NSRange(location: match.range.location, length: 1)
        let suffixRange = NSRange(location: match.range.location + match.range.length - 1, length: 1)
        attributed.addAttribute(.foregroundColor, value: UIColor.clear, range: prefixRange)
        attributed.addAttribute(.foregroundColor, value: UIColor.clear, range: suffixRange)
      }
    }

    // 헤더 처리
    let headerPattern = "^# (.+)$"
    if let regex = try? NSRegularExpression(pattern: headerPattern, options: [.anchorsMatchLines]) {
      regex.enumerateMatches(in: text, range: fullRange) { match, _, _ in
        guard let match = match else { return }
        let headerRange = match.range(at: 1)

        attributed.addAttributes([
          .font: UIFont.boldSystemFont(ofSize: 22),
          .foregroundColor: UIColor.systemBlue
        ], range: headerRange)

        // # 기호 숨기기
        let hashRange = NSRange(location: match.range.location, length: 2)
        attributed.addAttribute(.foregroundColor, value: UIColor.clear, range: hashRange)
      }
    }

    // 커서 위치 유지 처리
    let selectedRange = textView.selectedRange
    textView.attributedText = attributed
    textView.selectedRange = selectedRange
  }
}

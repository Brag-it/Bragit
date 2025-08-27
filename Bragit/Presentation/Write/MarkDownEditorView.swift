//
//  MarkDownEditorView.swift
//  Bragit
//
//  Created by 이태윤 on 8/27/25.
//
import UIKit

import SnapKit
import Then

final class MarkdownEditorView: UIView {
  // 텍스트의 시각적 스타일과 레이아웃을 담당하는 TextKit2의 핵심 렌더링 매니저
  let layoutManager = NSTextLayoutManager()
  // 텍스트 데이터를 저장하는 객체
  let contentStorage = NSTextContentStorage()
  // 텍스트가 배치될 위치와 영역을 정의하는 컨테이너
  let textContainer = NSTextContainer()

  lazy var textView: UITextView = {
    let textView = UITextView(frame: .zero, textContainer: self.textContainer).then {
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
    return textView
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupTextKit2()
    setupLayout()
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
}

//
//  LimitedMenuTextView.swift
//  Bragit
//
//  Created by 이태윤 on 9/19/25.
//
import UIKit

final class LimitedMenuTextView: UITextView {
  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    // 복사, 붙여넣기, 공유 등 전부 차단
    return false
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()

    // 텍스트뷰 기본 속성 조정
    isEditable = false      // 편집 불가
    isSelectable = false    // 선택 불가
    dataDetectorTypes = []  // 자동 링크 탐지 제거

    // 기본 롱탭 제스처 차단
    gestureRecognizers?.forEach {
      if $0 is UILongPressGestureRecognizer {
        $0.isEnabled = false
      }
    }

    // UITextInteraction 텍스트/이미지 프리뷰 제거
    interactions.forEach {
      if String(describing: type(of: $0)).contains("UITextInteraction") {
        removeInteraction($0)
      }
    }
  }
}

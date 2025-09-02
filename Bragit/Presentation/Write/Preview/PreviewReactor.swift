//
//  PreviewReactor.swift
//  Bragit
//
//  Created by 이태윤 on 8/27/25.
//
import UIKit

import ReactorKit
import RxSwift
import RxFlow
import RxRelay

class PreviewReactor: Reactor, Stepper {
  var initialState: State
  let draft: PostDraft
  let steps = PublishRelay<Step>()
  private let disposeBag = DisposeBag()

  // 사용자 액션 정의 (사용자의 의도)
  enum Action {
    case tapDismiss
    case tapPop
    case tapAddTag
    case addTag(String)
    case tapRemoveTag(String)
  }

  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case appendTag(String)
    case removeTag(String)
  }

  // View의 상태 정의 (현재 View의 상태값)
  struct State {
    var title: String
    var content: NSAttributedString
    var thumbnails: [UIImage]
    var description: String
    var tags: [String] = []

    @Pulse var presentTagModal = false
  }

  init(draft: PostDraft) {
    self.draft = draft
    let images = PreviewReactor.extractImages(from: draft.content)
    let decription = PreviewReactor.extractDecription(from: draft.content, limit: 80)
    self.initialState = State(title: draft.title, content: draft.content, thumbnails: images, description: decription)
  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapDismiss:
      steps.accept(AppStep.dismiss)
      return .empty()

    case .tapPop:
      steps.accept(AppStep.pop)
      return .empty()

    case .tapAddTag:
      steps.accept(AppStep.writeTagSearch)
      return .empty()

    case .addTag(let tag):
      return .just(.appendTag(tag))

    case .tapRemoveTag(let tag):
      return .just(.removeTag(tag))
    }
  }
  // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
  // 상태 변화 신호 → 실제 상태 반영
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .appendTag(let tag):
      if !state.tags.contains(tag) {
        newState.tags.append(tag)
      }

    case .removeTag(let tag):
      newState.tags.removeAll { $0 == tag }
    }

    return newState
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }

  // NSAttributedString에서 이미지 뽑아 내기
  static func extractImages(from attributedString: NSAttributedString) -> [UIImage] {
    var images: [UIImage] = []

    attributedString.enumerateAttribute(
      .attachment, in: NSRange(location: 0, length: attributedString.length)
    ) { value, _, _ in
      if let attachment = value as? NSTextAttachment, let image = attachment.image {
        images.append(image)
      }
    }
    return images
  }

  // 요약
  static func extractDecription(from attributedString: NSAttributedString, limit: Int = 80) -> String {
    let plainText = attributedString.string
    let cleanedText = plainText
      .replacingOccurrences(of: "^\n+", with: "", options: .regularExpression) // 맨 앞 줄바꿈 제거
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let preview = String(cleanedText.prefix(limit))
    return preview
  }
}

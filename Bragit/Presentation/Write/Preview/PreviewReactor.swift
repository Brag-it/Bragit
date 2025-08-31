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
  }

  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
  }

  // View의 상태 정의 (현재 View의 상태값)
  struct State {
    var title: String
    var content: NSAttributedString
    var thumbnail: [UIImage]
    var decription: String
  }

  init(draft: PostDraft) {
    self.draft = draft
    let images = PreviewReactor.extractImages(from: draft.content)
    let decription = PreviewReactor.extractDecription(from: draft.content, limit: 80)
    self.initialState = State(title: draft.title, content: draft.content, thumbnail: images, decription: decription)
  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    }
  }
  // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
  // 상태 변화 신호 → 실제 상태 반영
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    }
    return newState
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }

  // NSAttributedString에서 이미지 뽑아 내기
  static func extractImages(from attributedString: NSAttributedString) -> [UIImage] {
    var images: [UIImage] = []

    attributedString.enumerateAttribute(.attachment,
                                        in: NSRange(location: 0,
                                                    length: attributedString.length)) { value, _, _ in
      if let attachment = value as? NSTextAttachment,
         let image = attachment.image {
        images.append(image)
      }
    }
    return images
  }

  // 요약
  static func extractDecription(from attributedString: NSAttributedString, limit: Int = 80) -> String {
    let plainText = attributedString.string
    let trimmed = plainText.trimmingCharacters(in: .whitespacesAndNewlines)
    let preview = String(trimmed.prefix(limit))
    return preview
  }
}

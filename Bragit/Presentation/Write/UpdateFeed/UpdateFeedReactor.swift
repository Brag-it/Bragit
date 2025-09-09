//
//  UpdateFeedReactor.swift
//  Bragit
//
//  Created by 이태윤 on 9/9/25.
//
import Foundation

import ReactorKit
import RxSwift
import RxFlow
import RxRelay
import Dependencies

class UpdateFeedReactor: Reactor, Stepper {
  var initialState: State
  let post: PostUpdate
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
    var postId: UUID
    var title: String
    var content: NSAttributedString
  }

  init(post: PostUpdate) {
    self.post = post
    self.initialState = State(
      postId: post.id,
      title: post.title,
      content: post.content)
  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {

    }

    // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
    // 상태 변화 신호 → 실제 상태 반영
    func reduce(state: State, mutation: Mutation) -> State {
      switch mutation {
      }
    }

    func transform(state: Observable<State>) -> Observable<State> {
      return state.observe(on: MainScheduler.instance)
    }
  }
}

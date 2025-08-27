//
//  WriteReactor.swift
//  Bragit
//
//  Created by 이태윤 on 8/22/25.
//
import ReactorKit
import RxSwift
import RxFlow
import RxRelay

class WriteReactor: Reactor, Stepper {
  var initialState: State
  let steps = PublishRelay<Step>()
  private let disposeBag = DisposeBag()

  // 사용자 액션 정의 (사용자의 의도)
  enum Action {
    case tapDismiss // 탭 닫기
    case textChanged(String) // 완료버튼 활성화
  }

  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case setDoneButtonEnabled(Bool)
  }

  // View의 상태 정의 (현재 View의 상태값)
  struct State {
    var isDoneButtonEnabled: Bool = false
  }

  init() {
    self.initialState = State()
  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapDismiss:
      steps.accept(AppStep.dismiss)
      return .empty()
    case .textChanged(let text):
      // 공백 제거 후 내용 유무 판단
      let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
      return .just(.setDoneButtonEnabled(!trimmed.isEmpty)) // 텍스트 작성을 했으면 true 안했으면 false
    }
  }
  // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
  // 상태 변화 신호 → 실제 상태 반영
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setDoneButtonEnabled(let isEnabled):
      newState.isDoneButtonEnabled = isEnabled
    }
    return newState
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }
}

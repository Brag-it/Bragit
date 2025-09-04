//
//  CancelAccountReactor.swift
//  Bragit
//
//  Created by seongjun cho on 9/4/25.
//

import ReactorKit
import RxSwift
import RxFlow
import RxRelay
import Then
import Dependencies

class CancelAccountReactor: Reactor, Stepper {
  var initialState: State
  let steps = PublishRelay<Step>()
  @Dependency(\.userManager) var userManager

  private let disposeBag = DisposeBag()
  // 사용자 액션 정의 (사용자의 의도)
  enum Action {
    case backButtonTap
    case checkBoxTap
    case cancelButtonTap
    case setUserInform
  }

  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case toggleAgree
    case setUserInform(User?)
  }

  // View의 상태 정의 (현재 View의 상태값)
  struct State: Then {
    var isAgree: Bool = false
    var user: User?
  }

  init() {
    self.initialState = State()
  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .setUserInform:
      @LocalStorage(location: .nowUser) var id: String?
      return userManager.rxfetchUsersBy(ids: [id ?? ""]).map {
        .setUserInform($0.first)
      }
    case .backButtonTap:
      steps.accept(AppStep.dismiss)
      return .empty()
    case .checkBoxTap:
      return .just(.toggleAgree)
    case .cancelButtonTap:

      return .empty()
    }
  }

  // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
  // 상태 변화 신호 → 실제 상태 반영
  func reduce(state: State, mutation: Mutation) -> State {
    switch mutation {
    case .toggleAgree:
      return state.with {
        $0.isAgree.toggle()
      }
    case .setUserInform(let user):
      return state.with {
        $0.user = user
      }
    }
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }
}

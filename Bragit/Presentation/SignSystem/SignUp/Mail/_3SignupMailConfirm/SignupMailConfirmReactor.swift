//
//  SignupMailConfirmReactor.swift
//  Bragit
//
//  Created by luca on 9/18/25.
//

import ReactorKit
import RxFlow
import RxRelay
import RxSwift

final class SignupMailConfirmReactor: Reactor, Stepper {
  // MARK: - Reactor
  enum Action {
    case tapNext
    case tapBack
  }

  enum Mutation {
  }

  struct State {
  }

  let initialState: State
  let info: UserRegistrationInfo

  // MARK: - Stepper
  let steps = PublishRelay<Step>()

  // MARK: - Init
  init(info: UserRegistrationInfo) {
    self.info = info
    self.initialState = State()
  }

  // MARK: - Mutate
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapBack:
      steps.accept(AppStep.pop)
      return .empty()
    case .tapNext:
      // 디버그: 로그인
      // steps.accept(AppStep.login)
      steps.accept(AppStep.signupImageUpload)
      return .empty()
    }
  }

  // MARK: - Reduce
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    return newState
  }
}

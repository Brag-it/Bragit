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
  }

  enum Mutation {
  }

  struct State {
  }

  let initialState: State

  // MARK: - Stepper
  let steps = PublishRelay<Step>()

  // MARK: - Init
  init() {
    self.initialState = State()
  }

  // MARK: - Mutate
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapNext:
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

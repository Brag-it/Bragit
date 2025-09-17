//
//  SignupMailTermsReactor.swift
//  Bragit
//
//  Created by luca on 9/18/25.
//

import ReactorKit
import RxFlow
import RxRelay
import RxSwift

final class SignupMailTermsReactor: Reactor, Stepper {
    // MARK: - Reactor
  enum Action {
      // Define user actions if needed later (e.g., case nextTapped)
  }

  enum Mutation {
      // Define state mutations if needed later
  }

  struct State {
      // Define view state properties if needed later
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
    return .empty()
  }

    // MARK: - Reduce
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
      // Apply mutations to state here when added
    return newState
  }
}


//
//  SignupTagSelectReactor.swift
//  Bragit
//
//  Created by luca on 9/18/25.
//

import ReactorKit
import RxFlow
import RxRelay
import RxSwift

final class SignupTagSelectReactor: Reactor, Stepper {
  // MARK: - Reactor
  enum Action {
    case tapNext(tags: [Tag])
    case tapBack
    case tapLater
  }

  enum Mutation {
    case setLoading(Bool)
    case setError(String?)
  }

  struct State {
    var isLoading: Bool = false
    var errorMessage: String?
  }

  let initialState: State

  // MARK: - Stepper
  let steps = PublishRelay<Step>()
  @LocalStorage(location: .favoriteTags) private var favoriteTags: [Tag]?

  // MARK: - Init
  init() {
    self.initialState = State()
  }

  // MARK: - Mutate
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapNext(let tags):
      self.favoriteTags = tags
      steps.accept(AppStep.home)
      return .empty()
    case .tapBack:
      steps.accept(AppStep.pop)
      return .empty()
    case .tapLater:
      self.favoriteTags = []
      steps.accept(AppStep.home)
      return .empty()
    }
  }

  // MARK: - Reduce
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    // Apply mutations to state here when added
    return newState
  }
}

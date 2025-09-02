//
//  TagCheckReactor.swift
//  Bragit
//
//  Created by luca on 9/2/25.
//

import ReactorKit
import RxFlow
import RxRelay
import Dependencies

final class TagCheckReactor: Reactor, Stepper {
  enum Action {
    case tapLater
    case tapNext
  }

  enum Mutation {
    case setLoading(Bool)
    case setError(String?)
    case setRegistrationComplete(Bool)
  }

  struct State {
    var isLoading: Bool = false
    var errorMessage: String?
  }

  let initialState = State()
  let steps = PublishRelay<Step>()
  private let userInfo: UserRegistrationInfo

  @Dependency(\.supabase) private var supabase
  @Dependency(\.authClient) private var authClient

  init(userInfo: UserRegistrationInfo) {
    self.userInfo = userInfo
  }

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapLater:
        //
    case .tapNext:
        //
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setLoading(let isLoading):
      newState.isLoading = isLoading
    case .setError(let message):
      newState.errorMessage = message
    case .setRegistrationComplete:
      break
    }
    return newState
  }
}

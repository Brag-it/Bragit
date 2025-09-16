//
//  MailConfirmReactor.swift
//  Bragit
//
//  Created by luca on 9/14/25.
//

import Foundation
import ReactorKit
import RxSwift
import RxRelay
import RxFlow

final class MailConfirmReactor: Reactor, Stepper {
  // MARK: - Action
  enum Action {
    case updateCode(String)
    case tapNext
    case tapHelp
    case tapBack
  }

  // MARK: - Mutation
  enum Mutation {
    case setCode(String)
    case setNextEnabled(Bool)
  }

  // MARK: - State
  struct State {
    var code: String = ""
    var isNextEnabled: Bool = false
  }

  // MARK: - Reactor requirements
  let initialState: State

  // MARK: - Stepper
  let steps = PublishRelay<Step>()

  init() {
    self.initialState = State()
  }

  // MARK: - Mutate
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .updateCode(let input):
      let digits = input.filter { $0.isNumber }
      let limited = String(digits.prefix(6))
      let enabled = (limited.count == 6)
      return .concat([
        .just(.setCode(limited)),
        .just(.setNextEnabled(enabled))
      ])

    case .tapNext:
      return .empty()

    case .tapHelp:
      return .empty()

    case .tapBack:
      steps.accept(AppStep.pop)
      return .empty()
    }
  }

  // MARK: - Reduce
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setCode(let code):
      newState.code = code

    case .setNextEnabled(let enabled):
      newState.isNextEnabled = enabled
    }
    return newState
  }
}

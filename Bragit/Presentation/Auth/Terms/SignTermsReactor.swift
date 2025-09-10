//
//  SignTermsReactor.swift
//  Bragit
//
//  Created by luca on 9/10/25.
//

import Foundation

import ReactorKit
import RxFlow
import RxSwift
import RxRelay

final class SignTermsReactor: Reactor, Stepper {

  // View -> Reactor
  enum Action {
    case tapBack
    case tapAllㄴ
    case tapService
    case tapPrivacy
    case tapMarketing
    case tapNext
  }

  // Internal mutations
  enum Mutation {
    case setService(Bool)
    case setPrivacy(Bool)
    case setMarketing(Bool)
    case setProceed(Bool)
  }

  // Reactor -> View
  struct State {
    var serviceAccepted: Bool = false
    var privacyAccepted: Bool = false
    var marketingAccepted: Bool = false
    var proceed: Bool = false
  }

  let initialState: State
  let steps = PublishRelay<Step>()

  init() {
    self.initialState = State()
  }

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapBack:
      steps.accept(AppStep.pop)
      return .empty()
    case .tapAll:
      let service = currentState.serviceAccepted
      let privacy = currentState.privacyAccepted
      let marketing = currentState.marketingAccepted
      let shouldCheckAll = !(service && privacy && marketing)
      return .concat([
        .just(.setService(shouldCheckAll)),
        .just(.setPrivacy(shouldCheckAll)),
        .just(.setMarketing(shouldCheckAll))
      ])

    case .tapService:
      return .just(.setService(!currentState.serviceAccepted))

    case .tapPrivacy:
      return .just(.setPrivacy(!currentState.privacyAccepted))

    case .tapMarketing:
      return .just(.setMarketing(!currentState.marketingAccepted))

    case .tapNext:
      // Only proceed if required terms are accepted
      guard currentState.serviceAccepted && currentState.privacyAccepted else {
        return .empty()
      }
      // Pulse proceed: true -> false
      return .concat([
        .just(.setProceed(true)),
        .just(.setProceed(false))
      ])
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setService(let value):
      newState.serviceAccepted = value
    case .setPrivacy(let value):
      newState.privacyAccepted = value
    case .setMarketing(let value):
      newState.marketingAccepted = value
    case .setProceed(let value):
      newState.proceed = value
    }
    return newState
  }

  func transform(state: Observable<State>) -> Observable<State> {
    state.observe(on: MainScheduler.instance)
  }
}

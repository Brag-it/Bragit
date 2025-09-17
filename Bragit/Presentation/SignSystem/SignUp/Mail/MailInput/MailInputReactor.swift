//
//  MailOnlyReactor.swift
//  Bragit
//
//  Created by luca on 9/15/25.
//

import Foundation

import Dependencies
import ReactorKit
import RxFlow
import RxSwift
import RxRelay

final class MailInputReactor: Reactor, Stepper {
  enum Action {
    // case validateNickname(String)
  }

  enum Mutation {
    // case setChecking(Bool)
    // case setNickname(valid: Bool, text: String)
  }

  struct State {
    // var isChecking: Bool = false
    // var nicknameValid: Bool = false
    // var nicknameStatusText: String = " "
  }

  let initialState: State
  let steps = PublishRelay<Step>()

  // @Dependency(\.userManager) private var userManager: UserManagerProtocol

  init() {
    self.initialState = State()
  }
}

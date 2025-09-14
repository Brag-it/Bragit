//
//  MailInfoReactor.swift
//  Bragit
//
//  Created by luca on 9/14/25.
//

import Foundation

import Dependencies
import ReactorKit
import RxFlow
import RxSwift
import RxRelay

final class MailInfoReactor: Reactor, Stepper {
  enum Action {
    case validateNickname(String)
  }

  enum Mutation {
    case setChecking(Bool)
    case setNickname(valid: Bool, text: String)
  }

  struct State {
    var isChecking: Bool = false
    var nicknameValid: Bool = false
    var nicknameStatusText: String = " "
  }

  let initialState: State
  let steps = PublishRelay<Step>()

  @Dependency(\.userManager) private var userManager: UserManagerProtocol

  init() {
    self.initialState = State()
  }

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .validateNickname(let raw):
      let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)

      // 1) Local format validation first
      guard AppleInfoValidator.isValidNickname(name) else {
        return .just(.setNickname(valid: false, text: "사용 불가한 닉네임입니다"))
      }

      // 2) Server duplication check
      let start = Observable.just(Mutation.setChecking(true))
      let check = userManager.rxhasNickName(nickName: name)
        .map { isTaken -> Mutation in
          if isTaken {
            return .setNickname(valid: false, text: "사용 중인 닉네임입니다")
          } else {
            return .setNickname(valid: true, text: "사용 가능한 닉네임입니다")
          }
        }
        .catch { _ in
          .just(.setNickname(valid: false, text: "닉네임 확인 실패"))
        }
      let end = Observable.just(Mutation.setChecking(false))

      return .concat([start, check, end])
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setChecking(let flag):
      newState.isChecking = flag
      if flag {
        newState.nicknameStatusText = "중복 확인 중..."
      }
    case .setNickname(let valid, let text):
      newState.nicknameValid = valid
      newState.nicknameStatusText = text
    }
    return newState
  }

  func transform(state: Observable<State>) -> Observable<State> {
    state.observe(on: MainScheduler.instance)
  }
}

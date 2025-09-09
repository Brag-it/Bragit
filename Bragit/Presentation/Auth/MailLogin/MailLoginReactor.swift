//
//  MailLoginReactor.swift
//  Bragit
//
//  Created by luca on 9/9/25.
//

import Dependencies
import Foundation
import ReactorKit
import RxFlow
import RxRelay
import RxSwift
import Supabase

final class MailLoginReactor: Reactor, Stepper {
  typealias Reactor = MailLoginReactor
  enum Action {
    case tapBack
    case updateEmail(String)
    case updatePassword(String)
    case tapLogin
    case tapForgotPassword
  }

  enum Mutation {
    case setEmail(String)
    case setPassword(String)
    case setMailValid(Bool)
    case setPasswordValid(Bool)
    case setLoading(Bool)
    case setError(String?)
  }

  struct State {
    var mail: String = ""
    var password: String = ""
    var isMailValid: Bool = false
    var isPasswordValid: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?
    var canLogin: Bool {
      isMailValid && isPasswordValid && !isLoading
    }
  }

  let initialState: State
  let steps = PublishRelay<Step>()
  @Dependency(\.supabase) private var supabase
  @Dependency(\.authClient) private var authClient

  init() {
    self.initialState = State()
  }

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapBack:
      steps.accept(AppStep.pop)
      return .empty()
    case .updateEmail(let mail):
      let isValid = UserInfoValidator.isValidMail(mail)
      return .concat([
        .just(.setEmail(mail)),
        .just(.setMailValid(isValid))
      ])
    case .updatePassword(let password):
      let isValid = UserInfoValidator.isValidPassword(password)
      return .concat([
        .just(.setPassword(password)),
        .just(.setPasswordValid(isValid))
      ])
    case .tapLogin:
      guard currentState.canLogin else { return .empty() }
      return performLogin()
    case .tapForgotPassword:
      steps.accept(AppStep.findPwd)
      return .empty()
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setEmail(let mail):
      newState.mail = mail
    case .setPassword(let password):
      newState.password = password
    case .setMailValid(let valid):
      newState.isMailValid = valid
    case .setPasswordValid(let valid):
      newState.isPasswordValid = valid
    case .setLoading(let loading):
      newState.isLoading = loading
      if loading {
        newState.errorMessage = nil
      }
    case .setError(let message):
      newState.errorMessage = message
    }
    return newState
  }

  // 중요: 상태 스트림을 메인 스레드로 보냅니다.
  func transform(state: Observable<State>) -> Observable<State> {
    state.observe(on: MainScheduler.instance)
  }

  private func performLogin() -> Observable<Mutation> {
    return Observable.create { [weak self] observer in
      guard let self else {
        observer.onCompleted()
        return Disposables.create()
      }

      Task {
        do {
          observer.onNext(.setLoading(true))

          try await self.supabase.auth.signIn(
            email: self.currentState.mail,
            password: self.currentState.password
          )

          let session = try await self.supabase.auth.session
          let userId = session.user.id.uuidString

          UserDefaults.standard.set(userId, forKey: LocalStorageCase.nowUser.rawValue)

          observer.onNext(.setLoading(false))
          observer.onCompleted()

          await MainActor.run {
            self.steps.accept(AppStep.home)
          }
        } catch {
          let errorMessage: String
          if error.localizedDescription.contains("Invalid login credentials") {
            errorMessage = "이메일 또는 비밀번호가 이상함"
          } else if error.localizedDescription.contains("Email not confirmed") {
            errorMessage = "이메일 인증이 필요"
          } else {
            errorMessage = "로그인 실패: \(error.localizedDescription)"
          }

          observer.onNext(.setError(errorMessage))
          observer.onNext(.setLoading(false))
          observer.onCompleted()
        }
      }
      return Disposables.create()
    }
  }
}

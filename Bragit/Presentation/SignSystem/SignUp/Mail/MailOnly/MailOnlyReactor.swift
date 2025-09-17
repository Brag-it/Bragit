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
import Supabase

final class MailOnlyReactor: Reactor, Stepper {
  // View -> Reactor
  enum Action {
    case tapNext(email: String)
  }

  // Internal state changes
  enum Mutation {
    case setLoading(Bool)
    case setError(String?)
  }

  // Reactor -> View
  struct State {
    var isLoading: Bool = false
    var errorMessage: String?
  }

  let initialState: State
  let steps = PublishRelay<Step>()

  @Dependency(\.supabase) private var supabase

  init() {
    self.initialState = State()
  }

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapNext(let email):
      return .concat([
        .just(.setLoading(true)),
        sendOTP(email: email)
          .catch { .just(.setError("인증 메일 발송 실패: \($0.localizedDescription)")) },
        .just(.setLoading(false))
      ])
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    var state = state
    switch mutation {
    case .setLoading(let loading):
      state.isLoading = loading
    case .setError(let message):
      state.errorMessage = message
    }
    return state
  }

  private func sendOTP(email: String) -> Observable<Mutation> {
    .create { [weak self] observer in
      guard let self else { return Disposables.create() }
      let task = Task {
        do {
          try await self.supabase.auth.signInWithOTP(email: email, shouldCreateUser: true)
          KeychainMailStore.save(email)
          await MainActor.run {
            self.steps.accept(AppStep.signupMailConfirm)
          }
          observer.onNext(.setError(nil))
          observer.onCompleted()
        } catch {
          observer.onNext(.setError(error.localizedDescription))
          observer.onCompleted()
        }
      }
      return Disposables.create { task.cancel() }
    }
  }
}

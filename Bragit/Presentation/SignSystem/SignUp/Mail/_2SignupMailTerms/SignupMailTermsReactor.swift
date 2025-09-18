//
//  SignupMailTermsReactor.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import Foundation

import Dependencies
import ReactorKit
import RxFlow
import RxRelay
import RxSwift
import Supabase

final class SignupMailTermsReactor: Reactor, Stepper {
  enum Action {
    case tapNext
  }

  enum Mutation {}

  struct State {}

  let initialState: State = State()
  let steps = PublishRelay<Step>()

  @Dependency(\.supabase) private var supabase

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapNext:
      return Observable.create { [weak self] observer in
        guard let self else { return Disposables.create() }
        let task = Task {
          do {
            if let email = KeychainMailStore.load(), !email.isEmpty {
              try await self.supabase.auth.signInWithOTP(email: email, shouldCreateUser: true)
            } else {
              print("[Signup][Terms] No pending email to send OTP")
            }
            await MainActor.run { self.steps.accept(AppStep.signupMailConfirm) }
            observer.onCompleted()
          } catch {
            print("[Signup][Terms] send OTP failed: \(error)")
            await MainActor.run { self.steps.accept(AppStep.signupMailConfirm) }
            observer.onCompleted()
          }
        }
        return Disposables.create { task.cancel() }
      }
    }
  }

  func reduce(state: State, mutation: Mutation) -> State { state }
}

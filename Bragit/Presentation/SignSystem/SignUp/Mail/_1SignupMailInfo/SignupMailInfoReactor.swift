//
//  SignupMailInfoReactor.swift
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

final class SignupMailInfoReactor: Reactor, Stepper {
  // MARK: - Reactor
  enum Action {
    case checkEmail(String)
    case tapNext(mail: String, password: String, nickname: String)
  }

  enum Mutation {
    case setMailStatus(style: MailStatusStyle, text: String)
  }

  enum MailStatusStyle {
    case none
    case loading
    case accept
    case reject
  }

  struct State {
    var mailStatusStyle: MailStatusStyle = .none
    var mailStatusText: String = " "
  }

  let initialState: State = State()
  let steps = PublishRelay<Step>()

  @Dependency(\.supabase) private var supabase

  // MARK: - Mutate
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .checkEmail(let raw):
      let email = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      guard Self.isValidEmail(email) else { return .just(.setMailStatus(style: .reject, text: "사용 불가한 이메일입니다")) }

      return Observable<Mutation>.create { observer in
        let task = Task {
          do {
            let result = try await EmailAvailabilityChecker.check(email: email)
            if result.exists {
              observer.onNext(.setMailStatus(style: .reject, text: "이미 사용 중인 이메일입니다"))
            } else {
              observer.onNext(.setMailStatus(style: .accept, text: "사용 가능한 이메일입니다"))
            }
            observer.onCompleted()
          } catch {
            observer.onNext(.setMailStatus(style: .reject, text: "이메일 확인 실패"))
            observer.onCompleted()
          }
        }
        return Disposables.create { task.cancel() }
      }

    case .tapNext(let mail, let password, let nickname):
      let trimmedMail = mail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
      let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmedMail.isEmpty, !trimmedPassword.isEmpty, !trimmedNickname.isEmpty else { return .empty() }

      return Observable.create { [weak self] observer in
        guard let self else { return Disposables.create() }
        let task = Task {
          KeychainMailStore.save(trimmedMail)
          KeychainHelper.set(trimmedPassword, forKey: "pendingPassword")
          UserDefaults.standard.set(trimmedNickname, forKey: "pending.nickname")

          await MainActor.run { self.steps.accept(AppStep.signupMailTerms) }
          observer.onCompleted()
        }
        return Disposables.create { task.cancel() }
      }
    }
  }

  // MARK: - Reduce
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setMailStatus(let style, let text):
      newState.mailStatusStyle = style
      newState.mailStatusText = text
    }
    return newState
  }

  // MARK: - Utils
  private static func isValidEmail(_ email: String) -> Bool {
    guard !email.isEmpty else { return false }
    let pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
    do {
      let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
      let range = NSRange(location: 0, length: email.utf16.count)
      return regex.firstMatch(in: email, options: [], range: range) != nil
    } catch {
      return false
    }
  }
}

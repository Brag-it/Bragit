//
//  SignupMailInfoReactor.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import ReactorKit
import RxFlow
import RxRelay
import RxSwift
import Foundation

final class SignupMailInfoReactor: Reactor, Stepper {
  // MARK: - Reactor
  enum Action {
    case checkEmail(String)
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

  let initialState: State

  // MARK: - Stepper
  let steps = PublishRelay<Step>()

  // MARK: - Init
  init() {
    self.initialState = State()
  }

  // MARK: - Mutate
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .checkEmail(let raw):
      let email = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

      // 간단한 로컬 형식 검사
      guard Self.isValidEmail(email) else {
        return .just(.setMailStatus(style: .reject, text: "올바른 이메일 형식이 아닙니다"))
      }

      let start = Observable.just(Mutation.setMailStatus(style: .loading, text: "확인 중..."))

      let check = Observable<Mutation>.create { observer in
        let task = Task {
          do {
            let result = try await EmailAvailabilityChecker.check(email: email)
            if result.exists {
              let providers = result.user?.identities?.compactMap { $0.provider }.joined(separator: ", ") ?? "unknown"
              observer.onNext(.setMailStatus(style: .reject, text: "이미 가입된 이메일입니다 (\(providers))"))
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

      return .concat([start, check])
    }
  }

  // Local email format validation
  private static func isValidEmail(_ email: String) -> Bool {
    guard !email.isEmpty else { return false }
    // Basic RFC 5322-like pattern (case-insensitive)
    let pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
    do {
      let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
      let range = NSRange(location: 0, length: email.utf16.count)
      return regex.firstMatch(in: email, options: [], range: range) != nil
    } catch {
      return false
    }
  }

  // MARK: - Reduce
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case let .setMailStatus(style, text):
      newState.mailStatusStyle = style
      newState.mailStatusText = text
    }
    return newState
  }
}

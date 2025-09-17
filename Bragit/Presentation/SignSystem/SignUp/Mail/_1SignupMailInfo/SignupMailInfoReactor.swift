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

      guard Self.isValidEmail(email) else {
        print("[Signup][MailCheck] invalid_format email=\(email)")
        return .empty()
      }

      // 콘솔 출력만 수행, UI 상태 변경 없음
      return Observable<Mutation>.create { observer in
        let task = Task {
          do {
            let result = try await EmailAvailabilityChecker.check(email: email)
            if result.exists {
              let providers = result.user?.identities?.compactMap { $0.provider }.joined(separator: ", ") ?? "unknown"
              let status = (result.status ?? "").lowercased()
              switch status {
              case "waiting":
                print("[Signup][MailCheck] status=waiting (인증 대기) providers=\(providers) email=\(email)")
              case "confirmed":
                print("[Signup][MailCheck] status=confirmed (이미 가입) providers=\(providers) email=\(email)")
              case "banned":
                print("[Signup][MailCheck] status=banned (제한) providers=\(providers) email=\(email)")
              default:
                print("[Signup][MailCheck] status=unknown providers=\(providers) email=\(email)")
              }
            } else {
              print("[Signup][MailCheck] status=not_found (사용 가능) email=\(email)")
            }
            observer.onCompleted()
          } catch {
            print("[Signup][MailCheck] check failed: \(error) email=\(email)")
            observer.onCompleted()
          }
        }
        return Disposables.create { task.cancel() }
      }
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


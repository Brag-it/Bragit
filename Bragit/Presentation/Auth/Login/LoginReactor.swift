//
//  LoginReactor.swift
//  Bragit
//
//  Created by luca on 8/21/25.
//

// 1. VC가 .tapApple(idToken, nonce) 액션 전송
// 2. Supabase 교환(AuthService) -> 세션(uid/email)
// 3. UserChecker.exists(uid) -> true면 메인, false면 회원가입 각각 state 방출

import CryptoKit
import Foundation

import Dependencies
import ReactorKit
import RxFlow
import RxRelay
import RxSwift
import Supabase

final class LoginReactor: Reactor, Stepper {

  // View -> Reactor
  enum Action {
    case tapApple(idToken: String, nonce: String, mail: String?)
    case tapAppleButton
    case tapSignUp
    case tapNext
  }

  // 내부 상태 변경
  enum Mutation {
    case setLoading(Bool)
    case setError(String?)
    case setNonce(raw: String?, hashed: String?)
  }

  // Reactor -> View
  struct State {
    var isLoading = false
    var errorMessage: String?
    var appleNonce: String?
    var appleHashsedNonce: String?
  }

  var initialState = State()
  let steps = PublishRelay<Step>()
  @Dependency(\.authClient) private var authClient
  @Dependency(\.supabase) private var supabase

  init() {
    self.initialState = State()
  }

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapApple(let idToken, let nonce, let mail):
      return Observable.concat([
        .just(.setLoading(true)),
        signInWithApple(idToken: idToken, nonce: nonce)
          .catch { .just(.setError("로그인 실패: \($0.localizedDescription)")) },
        // new line
        checkUserRegistrationAndRoute(mail: mail),
        .just(.setLoading(false)),
        .just(.setNonce(raw: nil, hashed: nil))
      ])
    case .tapAppleButton:
      let raw = Self.randomNonce()
      let hashed = Self.sha256(raw)
      return .just(.setNonce(raw: raw, hashed: hashed))
    case .tapSignUp:
      steps.accept(AppStep.signup(initialMail: nil))
      return .empty()
    case .tapNext:
      steps.accept(AppStep.home)
      return .empty()
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    var state = state
    switch mutation {
    case .setLoading(let load): state.isLoading = load
    case .setError(let msg): state.errorMessage = msg
    case .setNonce(let raw, let hashed):
      state.appleNonce = raw
      state.appleHashsedNonce = hashed
    }
    return state
  }

  func transform(state: Observable<State>) -> Observable<State> {
    state.observe(on: MainScheduler.instance)
  }

  private func checkUserRegistrationAndRoute(mail: String?) -> Observable<Mutation> {
    Observable<Mutation>.create { [weak self] observer in
      guard let self else { return Disposables.create() }
      Task { [weak self] in
        guard let self else {
          observer.onCompleted()
          return
        }
        do {
          let session = try await self.supabase.auth.session
          let userId = session.user.id

          print("[apple]: \(session.user.email as Any), \(mail as Any)")

          let users: [UserInfo] = try await self.supabase
            .from("User_Info")
            .select()
            .eq("id", value: userId)
            .execute()
            .value

          if users.first != nil {
            await MainActor.run { self.steps.accept(AppStep.home) }
          } else {
            //            let email = mail
            await MainActor.run { self.steps.accept(AppStep.signup(initialMail: mail)) }
          }
          observer.onCompleted()
        } catch {
          observer.onNext(.setError("가입 여부 확인 실패: \(error.localizedDescription)"))
          observer.onCompleted()
        }
      }
      return Disposables.create()
    }
  }

  private static func randomNonce(length: Int = 32) -> String {
    precondition(length > 0)
    let charSet: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remaining = length

    while remaining > 0 {
      var random: UInt8 = 0
      let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
      if status != errSecSuccess { fatalError("Unable to generate nonce.") }
      if random < charSet.count {
        result.append(charSet[Int(random % UInt8(charSet.count))])
        remaining -= 1
      }
    }
    return result
  }

  private static func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
  }

  // MARK: - Private
  private func signInWithApple(idToken: String, nonce: String) -> Observable<Mutation> {
    Observable<Mutation>.create { [weak self] observer in
      guard let self else { return Disposables.create() }
      Task {
        do {
          try await self.authClient.signInWithApple(idToken, nonce)
          observer.onNext(.setError(nil))
          observer.onCompleted()
        } catch {
          observer.onNext(.setError(error.localizedDescription))
          observer.onCompleted()
        }
      }
      return Disposables.create()
    }
  }
}

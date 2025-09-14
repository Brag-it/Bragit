//
//  LoginReactor.swift
//  Bragit
//
//  Created by luca on 8/21/25.
//

// 1. VC가 .tapApple(idToken, nonce) 액션 전송
// 2. Supabase 교환(AuthService) -> 세션(uid/email)
// 3. UserChecker.exists(uid) -> true면 메인, false면 회원가입 각각 state 방출
// 아 리액트 어렵다

import Foundation

import CryptoKit
import Dependencies
import Functions
import ReactorKit
import RxFlow
import RxRelay
import RxSwift
import Supabase

final class MainLoginReactor: Reactor, Stepper {

  // View -> Reactor
  enum Action {
    case tapApple(idToken: String, nonce: String, mail: String?, authCode: String)
    case tapAppleButton
    case tapSignUp
    case tapNext
    case tapMailLogin
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

  struct Response: Decodable {
    var success: Bool
    var refreshToken: String
  }

  var initialState = State()
  let steps = PublishRelay<Step>()
  private var disposeBag = DisposeBag()
  @Dependency(\.authClient) private var authClient
  @Dependency(\.supabase) private var supabase
  @Dependency(\.userManager) private var userManager

  init() {
    self.initialState = State()
  }

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapApple(let idToken, let nonce, let mail, let authCode):
      return .concat([
        .just(.setLoading(true)),
        signInWithApple(idToken: idToken, nonce: nonce)
          .catch { .just(.setError("로그인 실패: \($0.localizedDescription)")) },
        getRefreshToken(authCode: authCode)
          .flatMap { [weak self] refreshToken -> Observable<Mutation> in
            guard let self = self else { return .empty() }
            return self.checkUserRegistrationAndRoute(mail: mail, refreshToken: refreshToken)
          },
        .just(.setLoading(false)),
        .just(.setNonce(raw: nil, hashed: nil))
      ])
    case .tapAppleButton:
      let raw = Self.randomNonce()
      let hashed = Self.sha256(raw)
      return .just(.setNonce(raw: raw, hashed: hashed))
    case .tapMailLogin:
      steps.accept(AppStep.signInMail)
      return .empty()
    case .tapSignUp:
      // 일반(메일) 회원가입 시작
        steps.accept(AppStep.signupMailInput)
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

  private func checkUserRegistrationAndRoute(mail: String?, refreshToken: String?) -> Observable<Mutation> {
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

          // 1) Apple이 준 이메일이 있고, Supabase Auth의 기본 email이 비어 있다면
          //    user_metadata에 이메일 저장
          if session.user.email == nil || session.user.email?.isEmpty == true,
            let mail, !mail.isEmpty {
            do {
              try await self.supabase.auth.update(
                user: UserAttributes(
                  data: ["email": AnyJSON.string(mail)]
                )
              )
              print("[apple]: user_metadata email backfilled")
            } catch {
              print("[apple]: failed to backfill user_metadata email: \(error)")
            }
          }

          // 2) 가입 여부 확인
          let users: [User] = try await self.supabase
            .from("User_Info")
            .select()
            .eq("id", value: userId)
            .execute()
            .value

          if users.first != nil {
            // 기존 사용자: nowUser 저장 후 홈으로
            UserDefaults.standard.set(userId.uuidString, forKey: LocalStorageCase.nowUser.rawValue)
            await MainActor.run { self.steps.accept(AppStep.home) }
          } else {
            // 미가입: 회원가입 플로우로 (TagCheckReactor에서 nowUser 저장)
            await MainActor.run {
              self.steps.accept(
                AppStep.signupApple(
                  initialMail: mail,
                  refreshToken: refreshToken,
                  isAppleLogin: true
                )
              )
            }
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

  private func getRefreshToken(authCode: String) -> Observable<String> {
    return .create { [weak self] observer in
      guard let self = self else { return Disposables.create() }

      let task = Task {
        do {
          let response: Response = try await self.supabase.functions
            .invoke(
              "generate-refreshToken",
              options: FunctionInvokeOptions(body: ["authCode": authCode])
            )

          observer.onNext(response.refreshToken)
          observer.onCompleted()

        } catch {
          observer.onError(error)
        }
      }

      return Disposables.create {
        task.cancel()
      }
    }
  }
}

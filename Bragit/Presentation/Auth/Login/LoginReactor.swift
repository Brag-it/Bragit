//
//  LoginReactor.swift
//  Bragit
//
//  Created by luca on 8/21/25.
//

// 1. VC가 .tapApple(idToken, nonce) 액션 전송
// 2. Supabase 교환(AuthService) -> 세션(uid/email)
// 3. UserChecker.exists(uid) -> true면 메인, false면 회원가입 각각 state 방출

import Foundation
import ReactorKit
import RxSwift
import Supabase

final class LoginReactor: Reactor {
  // View -> Reactor
  enum Action {
    case tapApple(idToken: String, nonce: String)
  }

  // 내부 상태 변경
  enum Mutation {
    case setLoading(Bool)
    case setError(String?)
    case setRoute(Route?)
  }

  // Reactor -> View
  struct State {
    var isLoading = false
    var errorMessage: String?
    var route: Route?
  }

  // 화면 전환 의도 (지금은 로그인 성공만 표현)
  enum Route: Equatable {
    case signInIsComplete
  }

  let initialState = State()

  // Supabase 의존성 (현재 코드와 동일한 생성값을 기본 주입)
  private let supabase: SupabaseClient
  init(supabase: SupabaseClient = AuthClient.shared) {
    self.supabase = supabase
  }
  //

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    //
    case .tapApple(let idToken, let nonce):
      //    case .tapApple(idToken, nonce):
      //
      return Observable.concat([
        .just(.setLoading(true)),
        signInWithApple(idToken: idToken, nonce: nonce)
          .catch { .just(.setError("로그인 실패: \($0.localizedDescription)")) },
        .just(.setLoading(false))
      ])
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    var state = state
    switch mutation {
    case .setLoading(let load): state.isLoading = load
    case .setError(let msg): state.errorMessage = msg
    case .setRoute(let route): state.route = route
    }
    return state
  }

  // MARK: - Private
  private func signInWithApple(idToken: String, nonce: String) -> Observable<Mutation> {
    Observable<Mutation>.create { [weak self] observer in
      guard let self else { return Disposables.create() }
      Task {
        do {
          _ = try await self.supabase.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
              provider: .apple,
              idToken: idToken,
              nonce: nonce
            )
          )
          observer.onNext(.setError(nil))
          observer.onNext(.setRoute(.signInIsComplete))
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

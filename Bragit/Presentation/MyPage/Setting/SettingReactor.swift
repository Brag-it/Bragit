//
//  SettingReactor.swift
//  Bragit
//
//  Created by seongjun cho on 9/3/25.
//

import ReactorKit
import RxSwift
import RxFlow
import RxRelay
import Then
import Dependencies
import Foundation
import Supabase

class SettingReactor: Reactor, Stepper {
  var initialState: State
  let steps = PublishRelay<Step>()

  @Dependency(\.supabase) private var supabase

  private let disposeBag = DisposeBag()

  enum Action {
    case backButtonTap
    case cancelAccountButtonTap
    case logoutButtonTap
    case tapTerms
    case tapLicenses
  }

  enum Mutation {
    case noop
    case didLogout
  }

  struct State: Then { }

  init() {
    self.initialState = State()
  }

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .backButtonTap:
      steps.accept(AppStep.dismiss)
      return .just(.noop)

    case .cancelAccountButtonTap:
      return cancelAccount()

    case .logoutButtonTap:
      return logoutAndRouteToLogin()

    case .tapTerms:
      steps.accept(AppStep.terms)
      return .empty()

    case .tapLicenses:
      steps.accept(AppStep.openSource)
      return .empty()
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    switch mutation {
    case .noop, .didLogout:
      return state
    }
  }

  func transform(state: Observable<State>) -> Observable<State> {
    state.observe(on: MainScheduler.instance)
  }

  // MARK: - Private

  private func logoutAndRouteToLogin() -> Observable<Mutation> {
    return Observable<Mutation>.create { [weak self] observer in
      guard let self else {
        observer.onCompleted()
        return Disposables.create()
      }

      let task = Task {
        do {
          // 글로벌 범위로 리프레시 토큰까지 폐기하여 재실행 시 자동 세션 복원을 방지
          try await self.supabase.auth.signOut(scope: .global)

          // 로컬 저장소 정리
          UserDefaults.standard.removeObject(forKey: LocalStorageCase.nowUser.rawValue)
          KeychainMailStore.clear()

          await MainActor.run {
            self.steps.accept(AppStep.login)
          }
        } catch {
          // 실패해도 라우팅은 로그인으로 보냄 (UI 관점에서 로그아웃 처리)
          await MainActor.run {
            self.steps.accept(AppStep.login)
          }
        }
        observer.onNext(.didLogout)
        observer.onCompleted()
      }

      return Disposables.create {
        task.cancel()
      }
    }
  }

  private func cancelAccount() -> Observable<Mutation> {
    return Observable<Mutation>.deferred { [weak self] in
      guard let self else { return .empty() }
      // KeychainMailStore.clear()
      self.steps.accept(AppStep.cancelAccount)

      return .just(.noop)
    }
  }
}

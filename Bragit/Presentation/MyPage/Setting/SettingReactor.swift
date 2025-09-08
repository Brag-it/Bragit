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

class SettingReactor: Reactor, Stepper {
  var initialState: State
  let steps = PublishRelay<Step>()

  @Dependency(\.supabase) private var supabase

  private let disposeBag = DisposeBag()

  enum Action {
    case backButtonTap
    case cancelAccountButtonTap
    case logoutButtonTap
  }

  enum Mutation {
    case noop
    case didLogout
  }

  struct State: Then {
  }

  init() {
    self.initialState = State()
  }

  // 사용자 입력 → 상태 변화 신호로 변환
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .backButtonTap:
      steps.accept(AppStep.dismiss)
      return .just(.noop)

    case .cancelAccountButtonTap:
      steps.accept(AppStep.cancelAccount)
      return .just(.noop)

    case .logoutButtonTap:
      return logoutAndRouteToLogin()
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    switch mutation {
    case .noop:
      return state
    case .didLogout:
      return state
    }
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
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
          try await self.supabase.auth.signOut()

          UserDefaults.standard.removeObject(forKey: LocalStorageCase.nowUser.rawValue)

          KeychainMailStore.clear()

          await MainActor.run {
            self.steps.accept(AppStep.login)
          }
        } catch {
          await MainActor.run {
            self.steps.accept(AppStep.login)
          }
        }
        // Emit a mutation so `reduce` is reachable
        observer.onNext(.didLogout)
        observer.onCompleted()
      }

      return Disposables.create {
        task.cancel()
      }
    }
  }
}

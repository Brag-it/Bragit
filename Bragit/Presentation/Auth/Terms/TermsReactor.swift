//
//  TermsReactor.swift
//  Bragit
//
//  Created by luca on 8/28/25.
//

import CryptoKit
import Dependencies
import Foundation
import ReactorKit
import RxFlow
import RxRelay
import RxSwift
import Supabase

final class TermsReactor: Reactor, Stepper {
  // View -> Reactor
  enum Action {
    case tapNext
  }

  // 내부 상태 변경
  enum Mutation {
    case setLoading(Bool)
    case setError(String?)
    case setRegistrationComplete(Bool)
  }

  // Reactor -> View
  struct State {
    var serviceAccepted: Bool = false
    var privacyAccepted: Bool = false
    var marketingAccepted: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?
    var isRegistrationComplete: Bool = false

    var isAllAccepted: Bool {
      serviceAccepted && privacyAccepted && marketingAccepted
    }

    var canProceed: Bool {
      serviceAccepted && privacyAccepted
    }
  }

  let initialState = State()
  let steps = PublishRelay<Step>()
  private let userInfo: UserRegistrationInfo

  @Dependency(\.supabase) private var supabase
  @Dependency(\.authClient) private var authClient

  init(userInfo: UserRegistrationInfo) {
    self.userInfo = userInfo
  }

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapNext:
      steps.accept(AppStep.home)
      return .empty()
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    var state = state

    switch mutation {
    case .setLoading(let loading):
      state.isLoading = loading
    case .setError(let message):
      state.errorMessage = message
    case .setRegistrationComplete(let complete):
      state.isRegistrationComplete = complete
    }
    return state
  }

  func transform(state: Observable<State>) -> Observable<State> {
    state.observe(on: MainScheduler.instance)
  }

  private func registerUser() -> Observable<Mutation> {
    Observable.create { [weak self] observer in
      guard let self = self else { return Disposables.create() }
      Task { [weak self] in
        guard let self else {
          observer.onCompleted()
          return
        }
        do {
          let session = try await self.supabase.auth.session
          let userId = session.user.id
          let userInfo = UserInfo(
            id: userId,
            nickname: self.userInfo.nickname,
            profile: nil,
            provider: self.userInfo.isAppleLogin ? "apple" : "mail",
            signDate: Date(),
            latestUploaded: nil
          )

          try await self.saveUserInfo(userInfo)

          observer.onNext(.setRegistrationComplete(true))
          observer.onNext(.setLoading(false))
          observer.onCompleted()

          await MainActor.run { self.steps.accept(AppStep.home) }
        } catch {
          observer.onNext(.setError("회원가입 처리 중 오류가 발생했습니다"))
          observer.onNext(.setLoading(false))
          observer.onCompleted()
        }
      }
      return Disposables.create()
    }
  }

  private func saveUserInfo(_ userInfo: UserInfo) async throws {
    _ = try await supabase
      .from("User_Info")
      .insert(userInfo)
      .execute()
  }
}

struct UserInfo: Codable {
  let id: UUID
  let nickname: String
  let profile: String?
  let provider: String
  let signDate: Date
  let latestUploaded: Date?

  enum CodingKeys: String, CodingKey {
    case id
    case nickname
    case profile
    case provider
    case signDate = "sign_date"
    case latestUploaded = "latest_uploaded"
  }
}

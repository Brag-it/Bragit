//
//  TagCheckReactor.swift
//  Bragit
//
//  Created by luca on 9/2/25.
//

import Dependencies
import Foundation
import ReactorKit
import RxFlow
import RxRelay
import RxSwift

final class TagCheckReactor: Reactor, Stepper {
  enum Action {
    case tapLater
    case tapNext(tags: [Tag])
  }

  enum Mutation {
    case setLoading(Bool)
    case setError(String?)
    case setRegistrationComplete(Bool)
  }

  struct State {
    var isLoading: Bool = false
    var errorMessage: String?
  }

  let initialState = State()
  let steps = PublishRelay<Step>()
  private let userInfo: UserRegistrationInfo
  private let profileURL: String?

  @Dependency(\.supabase) private var supabase
  @Dependency(\.authClient) private var authClient
  @LocalStorage(location: .favoriteTags) private var favoriteTags: [Tag]?

  init(userInfo: UserRegistrationInfo, profileURL: String?) {
    self.userInfo = userInfo
    self.profileURL = profileURL
  }

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapLater:
      return registerUserAndFinish(profileURL: nil)
    case .tapNext(let tags):
      self.favoriteTags = tags
      return registerUserAndFinish(profileURL: self.profileURL)
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setLoading(let isLoading):
      newState.isLoading = isLoading
    case .setError(let message):
      newState.errorMessage = message
    case .setRegistrationComplete:
      break
    }
    return newState
  }

  private func registerUserAndFinish(profileURL: String?) -> Observable<Mutation> {
    return Observable.create { [weak self] observer in
      guard let self else {
        observer.onCompleted()
        return Disposables.create()
      }

      Task {
        do {
          observer.onNext(.setLoading(true))

          let session = try await self.supabase.auth.session
          let userId = session.user.id

          UserDefaults.standard.set(userId.uuidString, forKey: LocalStorageCase.nowUser.rawValue)

          let user = User(
            id: userId.uuidString,
            nickname: self.userInfo.nickname,
            profile: profileURL,
            provider: self.userInfo.isAppleLogin ? "apple" : "mail",
            signDate: Date(),
            latestUploaded: nil
          )

          try await self.saveUserInfo(user)

          observer.onNext(.setRegistrationComplete(true))
          observer.onNext(.setLoading(false))
          observer.onCompleted()

          await MainActor.run { self.steps.accept(AppStep.home) }
        } catch {
          observer.onNext(.setError("회원가입 중 오류 발생"))
          observer.onNext(.setLoading(false))
          observer.onCompleted()
        }
      }
      return Disposables.create()
    }
  }

  private func saveUserInfo(_ user: User) async throws {
    _ =
      try await supabase
      .from("User_Info")
      .insert(user)
      .execute()
  }
}

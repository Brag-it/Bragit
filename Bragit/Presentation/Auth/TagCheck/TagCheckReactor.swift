//
//  TagCheckReactor.swift
//  Bragit
//
//  Created by luca on 9/2/25.
//

import Foundation

import Dependencies
import ReactorKit
import RxFlow
import RxRelay
import RxSwift
import Supabase

final class TagCheckReactor: Reactor, Stepper {
  enum Action {
    case tapBack
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
    case .tapBack:
      steps.accept(AppStep.pop)
      return .empty()
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
          print("📝: 회원가입 시작 >>> isAppleLogin = \(self.userInfo.isAppleLogin)")
          observer.onNext(.setLoading(true))

          var userId: String

          if !self.userInfo.isAppleLogin {
            print("📝: 이메일 회원가입 진행 중")
            guard let password = self.userInfo.password else {
              print("📝: 비밀번호 없음")
              observer.onNext(.setError("비밀번호 필요"))
              observer.onNext(.setLoading(false))
              observer.onCompleted()
              return
            }

            print("📝: signUp 호출 >>> mail = \(self.userInfo.mail)")
            let signUpResult = try await self.supabase.auth.signUp(
              email: self.userInfo.mail,
              password: password
            )
            print("📝: signUp 성공")

            let user = signUpResult.user
            userId = user.id.uuidString
          } else {
            let session = try await self.supabase.auth.session
            userId = session.user.id.uuidString
          }
          // 현재 로그인한 유저를 로컬에 기억
          UserDefaults.standard.set(userId, forKey: LocalStorageCase.nowUser.rawValue)

          // 회원 정보 저장
          let user = User(
            id: userId,
            nickname: self.userInfo.nickname,
            profile: profileURL,
            provider: self.userInfo.isAppleLogin ? "apple" : "mail",
            signDate: Date(),
            latestUploaded: nil,
            refreshToken: self.userInfo.refreshToken
          )

          try await self.saveUserInfo(user)

          // 1) Apple/이메일 가입 모두에서 User_Info.email 컬럼에 저장
          let trimmedMail = self.userInfo.mail.trimmingCharacters(in: .whitespacesAndNewlines)
          if !trimmedMail.isEmpty {
            do {
              try await self.supabase
                .from("User_Info")
                .update(["email": trimmedMail])
                .eq("id", value: userId)
                .execute()
              print("[signup] User_Info.email updated")
            } catch {
              print("[signup] User_Info.email update failed: \(error)")
            }
          }
          observer.onNext(.setRegistrationComplete(true))
          observer.onNext(.setLoading(false))
          observer.onCompleted()

          await MainActor.run { self.steps.accept(AppStep.home) }
        } catch {
          print("📝: 에러 >>> \(error)")
          let errorMessage =
            if error.localizedDescription.contains("already registered") {
              "이미 가입된 이메일"
            } else {
              "회원가입 중 오류 발생: \(error.localizedDescription)"
            }
          observer.onNext(.setError(errorMessage))
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

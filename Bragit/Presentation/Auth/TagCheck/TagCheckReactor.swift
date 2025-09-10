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
      return registerUserAndFinish(profileURL: nil, tags: [])

    case .tapNext(let tags):
      return registerUserAndFinish(profileURL: self.profileURL, tags: tags)
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

  private func registerUserAndFinish(profileURL: String?, tags: [Tag]) -> Observable<Mutation> {
    return Observable.create { [weak self] observer in
      guard let self else {
        observer.onCompleted()
        return Disposables.create()
      }

      Task {
        do {
          observer.onNext(.setLoading(true))

          let userId: String = try await {
            if !self.userInfo.isAppleLogin {
              guard let password = self.userInfo.password else {
                observer.onNext(.setError("비밀번호 필요"))
                observer.onNext(.setLoading(false))
                observer.onCompleted()
                throw NSError(domain: "Signup", code: -1, userInfo: [NSLocalizedDescriptionKey: "Password missing"])
              }
              let signUpResult = try await self.supabase.auth.signUp(
                email: self.userInfo.mail,
                password: password
              )
              return signUpResult.user.id.uuidString
            } else {
              let session = try await self.supabase.auth.session
              return session.user.id.uuidString
            }
          }()

          UserDefaults.standard.set(userId, forKey: LocalStorageCase.nowUser.rawValue)
          self.favoriteTags = tags

          await MainActor.run {
            self.steps.accept(AppStep.home)
          }

          // 백그라운드 처리
          Task.detached(priority: .background) { [userInfo = self.userInfo, supabase = self.supabase] in
            do {
              // 유저 정보 저장
              let user = User(
                id: userId,
                nickname: userInfo.nickname,
                profile: profileURL,
                provider: userInfo.isAppleLogin ? "apple" : "mail",
                signDate: Date(),
                latestUploaded: nil,
                refreshToken: userInfo.refreshToken
              )
              _ = try await supabase.from("User_Info").insert(user).execute()

              let trimmedMail = userInfo.mail.trimmingCharacters(in: .whitespacesAndNewlines)
              if !trimmedMail.isEmpty {
                do {
                  try await supabase
                    .from("User_Info")
                    .update(["email": trimmedMail])
                    .eq("id", value: userId)
                    .execute()
                } catch {
                  print("[signup] User_Info.email update failed: \(error)")
                }
              }
            } catch {
              print("Post-signup background work failed: \(error)")
            }
          }

          // 뷰 상태 마무리
          observer.onNext(.setRegistrationComplete(true))
          observer.onNext(.setLoading(false))
          observer.onCompleted()

        } catch {
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
}

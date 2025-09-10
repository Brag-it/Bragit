//
//  UserProfileReactor.swift
//  Bragit
//
//  Created by 이태윤 on 9/8/25.
//

import UIKit

import ReactorKit
import RxSwift
import RxFlow
import RxRelay
import Then
import Dependencies
import Kingfisher

class UserProfileReactor: Reactor, Stepper {
  var initialState: State
  let user: User
  let steps = PublishRelay<Step>()
  let doReload = PublishRelay<Void>()

  private let disposeBag = DisposeBag()

  @Dependency(\.userManager) private var userManager
  @Dependency(\.postManager) private var postManager
  @Dependency(\.blockManager) private var blockManager
  @Dependency(\.reportManager) private var reportManager

  // 사용자 액션 정의 (사용자의 의도)
  enum Action {
    case setUserInform
    case loadPosts
    case loadNextPost
    case goToTagDetail(Tag)
    case backButtonTap
    case followButtonTapped
    case didTapPost(Post)
    case blockUser
    case reportUser
  }

  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case setFollowersCount(Int)
    case setFollowingsCount(Int)
    case setNickName(String)
    case setPosts([Post])
    case setLoading(Bool)
    case appendPosts([Post])
    case setProfileImage(String)
    case setIsFollowing(Bool)
  }

  // View의 상태 정의 (현재 View의 상태값)
  struct State: Then {
    var followersCount: Int = 0
    var followingsCount: Int = 0
    var posts: [Post] = []
    var hasNexPage: Bool = false
    var isLoading: Bool = false
    var nickName: String = ""
    var profileImage: String = ""
    var isFollowing: Bool = false
  }

  init(user: User) {
    self.user = user
    self.initialState = State()
  }

  // swiftlint:disable cyclomatic_complexity
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .setUserInform:
      @LocalStorage(location: .followUser) var followUsers: [String]?
      let isFollowing = { [user] in
        if followUsers != nil && followUsers!.contains(user.id) {
          return true
        } else {
          return false
        }
      }()

      return .merge([
        userManager.rxFetchFollowerCount(userId: user.id).map { .setFollowersCount($0) },
        userManager.rxFetchFollowingCount(userId: user.id).map { .setFollowingsCount($0) },
        .just(.setNickName(user.nickname ?? "")),
        .just(.setProfileImage(user.profile ?? "")),
        .just(.setIsFollowing(isFollowing))
      ])
    case .loadPosts:
      return postManager.rxFetchPostByAuthorId(authorId: user.id, from: 0, to: 10).map {
        .setPosts($0)
      }
    case .loadNextPost:
      guard currentState.isLoading == false, currentState.hasNexPage else {
        return .empty()
      }
      let postCount = self.currentState.posts.count
      @LocalStorage(location: .nowUser) var nowUserId: String?

      return .concat([
        .just(.setLoading(true)),
        postManager.rxFetchPostByAuthorId(authorId: nowUserId ?? "", from: postCount, to: postCount + 10)
          .map { .appendPosts($0) },
        .just(.setLoading(false))
      ])
    case .goToTagDetail(let tag):
      self.steps.accept(AppStep.tagInform(tag))
      return .empty()
    case .backButtonTap:
      steps.accept(AppStep.pop)
      return .empty()
    case .followButtonTapped:
      @LocalStorage(location: .followUser) var followUser: [String]?

      return Observable.create { [weak self] observer in
        guard let self = self else {
          observer.onCompleted()
          return Disposables.create()
        }

        Task {
          do {
            if followUser?.contains(self.user.id) == true {
              followUser = followUser?.filter { $0 != self.user.id }
              try await self.userManager.unfollowUser(id: self.user.id)
              observer.onNext(.setIsFollowing(false))
            } else {
              followUser = (followUser ?? []) + [self.user.id]
              try await self.userManager.followUser(id: self.user.id)
              observer.onNext(.setIsFollowing(true))
            }
            self.doReload.accept(())
            observer.onCompleted()
          } catch {
            observer.onError(error)
          }
        }
        return Disposables.create()
      }
    case .didTapPost(let post):
      self.steps.accept(AppStep.feedDetail(post: post))
      return .empty()
    case .blockUser:
      @LocalStorage(location: .blockUser) var blockUsers: [String]?
      @LocalStorage(location: .followUser) var followUser: [String]?

      return blockManager.rxBlockUser(blockId: user.id)
        .flatMap { [user, steps] _ -> Observable<Mutation> in
          blockUsers = (blockUsers ?? []) + [user.id]
          followUser = followUser?.filter { $0 != user.id }
          steps.accept(AppStep.pop)
          return .empty()
        }
    case .reportUser:
      return reportManager.rxReportUser(reportedId: user.id, relatedID: user.id)
        .flatMap { _ -> Observable<Mutation> in
          return .empty()
        }
    }
  }
  // swiftlint:enable cyclomatic_complexity

  // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
  // 상태 변화 신호 → 실제 상태 반영
  func reduce(state: State, mutation: Mutation) -> State {
    switch mutation {
    case .setPosts(let posts):
      return state.with {
        $0.hasNexPage = posts.count >= 10
        $0.posts = posts
      }
    case .setLoading(let isLoading):
      return state.with {
        $0.isLoading = isLoading
      }
    case .appendPosts(let posts):
      return state.with {
        $0.hasNexPage = posts.count >= 10
        $0.posts.append(contentsOf: posts)
      }
    case .setNickName(let nickName):
      return state.with {
        $0.nickName = nickName
      }
    case .setProfileImage(let profileImage):
      return state.with {
        KingfisherManager.shared.cache.removeImage(forKey: profileImage)
        $0.profileImage = profileImage
      }
    case .setFollowingsCount(let count):
      return state.with {
        $0.followingsCount = count
      }
    case .setFollowersCount(let count):
      return state.with {
        $0.followersCount = count
      }
    case .setIsFollowing(let isFollowing):
      return state.with {
        $0.isFollowing = isFollowing
      }
    }
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }
}

//
//  MyPageReactor.swift
//  Bragit
//
//  Created by 이태윤 on 8/26/25.
//

import UIKit

import ReactorKit
import RxSwift
import RxFlow
import RxRelay
import Then
import Dependencies
import Kingfisher

class MyPageReactor: Reactor, Stepper {
  var initialState: State
  let steps = PublishRelay<Step>()

  private let disposeBag = DisposeBag()

  @Dependency(\.userManager) private var userManager
  @Dependency(\.postManager) private var postManager
  // 사용자 액션 정의 (사용자의 의도)
  enum Action {
    case setUserInform
    case loadMyPost
    case loadNextPost
    case goToSetting
    case goToFollower
    case goToFollowing
    case goToFavoriteTag
    case goToTagDetail(Tag)
    case registImage(UIImage)
    case didTapPost(Post)
  }

  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case setFollowers([String])
    case setFollowings([String])
    case setFavoriteTags([Tag])
    case setNickName(String)
    case setPosts([Post])
    case setLoading(Bool)
    case appendPosts([Post])
    case setProfileImage(String)
    case setUserId(String)
  }

  // View의 상태 정의 (현재 View의 상태값)
  struct State: Then {
    var userId: String = ""
    var followers: [String] = []
    var followings: [String] = []
    var favoriteTags: [Tag] = []
    var posts: [Post] = []
    var hasNexPage: Bool = false
    var isLoading: Bool = false
    var nickName: String = ""
    var profileImage: String = ""
  }

  init() {
    self.initialState = State()
  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  // swiftlint:disable cyclomatic_complexity
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .setUserInform:
      @LocalStorage(location: .favoriteTags) var favoriteTags: [Tag]?
      @LocalStorage(location: .followUser) var followUsers: [String]?
      @LocalStorage(location: .nowUser) var nowUserId: String?

      if followUsers == nil {
        followUsers = []
      }

      if favoriteTags == nil {
        favoriteTags = []
      }

      if nowUserId == nil {
        print("⚠️ nowUserID is nil!!")
        nowUserId = ""
      }

      return .merge([
        .just(.setFollowings(followUsers ?? [])),
        .just(.setFavoriteTags(favoriteTags ?? [])),
        .just(.setUserId(nowUserId ?? "")),
        userManager.rxFetchFollowers().map { .setFollowers($0) },
        userManager.rxfetchUsersBy(ids: [nowUserId ?? ""]).flatMap { users -> Observable<Mutation> in
          guard let user = users.first else { return .empty() }
          return .of(.setNickName(user.nickname ?? ""), .setProfileImage(user.profile ?? ""))
        }
      ])
    case .loadMyPost:
      @LocalStorage(location: .nowUser) var nowUserId: String?
      return postManager.rxFetchPostByAuthorId(authorId: nowUserId ?? "", from: 0, to: 10).map {
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
    case .goToSetting:
      steps.accept(AppStep.setting)
      return .empty()
    case .goToFollower:
      Task {
        let users = try? await userManager.fetchUsersBy(ids: currentState.followers)
        steps.accept(AppStep.followersList(users ?? []))
      }
      return .empty()
    case .goToFollowing:
      Task {
        let users = try? await userManager.fetchUsersBy(ids: currentState.followings)
        steps.accept(AppStep.followingList(users ?? []))
      }
      return .empty()
    case .goToFavoriteTag:
      steps.accept(AppStep.favoriteList(currentState.favoriteTags))
      return .empty()
    case .goToTagDetail(let tag):
      self.steps.accept(AppStep.tagInform(tag))
      return .empty()
    case .registImage(let image):
      return userManager.rxProfileImageUpload(image: image.jpegData(compressionQuality: 0.8) ?? Data())
        .flatMap { _ in self.userManager.rxGetProfileURL() }
        .flatMap { url in
          self.userManager.rxUpdateUserProfileImage(imageURLstring: url)
            .asObservable()
            .map { _ in Mutation.setProfileImage(url) }
        }
    case .didTapPost(let post):
      self.steps.accept(AppStep.feedDetail(post: post))
      return .empty()
    }
  }
  // swiftlint:enable cyclomatic_complexity

  // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
  // 상태 변화 신호 → 실제 상태 반영
  func reduce(state: State, mutation: Mutation) -> State {
    switch mutation {
    case .setFollowers(let followers):
      return state.with {
        $0.followers = followers
      }
    case .setFollowings(let followings):
      return state.with {
        $0.followings = followings
      }
    case .setFavoriteTags(let favoriteTags):
      return state.with {
        $0.favoriteTags = favoriteTags
      }
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
    case .setUserId(let userId):
      return state.with {
        $0.userId = userId
      }
    }
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }
}

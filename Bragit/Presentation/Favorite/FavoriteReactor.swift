//
//  FavoriteReactor.swift
//  Bragit
//
//  Created by seongjun cho on 8/26/25.
//

import Foundation

import ReactorKit
import RxSwift
import RxFlow
import RxRelay
import Then
import Dependencies

class FavoriteReactor: Reactor, Stepper {
  var initialState: State
  @Dependency(\.postManager) var postManager
  private let disposeBag = DisposeBag()
  @LocalStorage(location: .favoriteTags) var favoriteTags: [Tag]?
  @LocalStorage(location: .followUser) var followUser: [String]?
  let steps = PublishRelay<Step>()

  enum PostType: Int {
    case tag = 0
    case user = 1
  }
  enum Action {
    case loadTagsPosts
    case loadNextTagsPosts
    case loadUsersPosts
    case loadNextUsersPosts
    case setPostType(PostType)
  }

  enum Mutation {
    case setLoading(Bool)
    case setPosts([Post])
    case appendPosts([Post])
    case setPostType(PostType)
  }

  struct State: Then {
    var posts: [Post] = []
    var isLoading: Bool = false
    var postType: PostType = .tag
  }

  init() {
    self.initialState = State()
  }

  func mutate(action: Action) -> Observable<Mutation> {
    if currentState.isLoading {
      return .empty()
    }
    let tags = favoriteTags?.map { $0.id }

    switch action {
    case .loadTagsPosts:
      return .concat([
        .just(.setLoading(true)),
        postManager
          .rxSearchFeed(
            tagIDs: tags ?? [],
            from: 0,
            to: 10)
          .map { .setPosts($0) },
        .just(.setLoading(false))
      ])
    case .loadNextTagsPosts:
      return .concat([
        .just(.setLoading(true)),
        postManager
          .rxSearchFeed(
            tagIDs: tags ?? [],
            from: self.currentState.posts.count,
            to: self.currentState.posts.count + 10)
          .map { .appendPosts($0) },
        .just(.setLoading(false))
      ])
    case .loadUsersPosts:
      return .concat([
        .just(.setLoading(true)),
        postManager
          .rxSearchFollowUserPost(
            followIds: followUser ?? [],
            from: 0,
            to: 10)
          .map { .setPosts($0) },
        .just(.setLoading(false))
      ])
    case .loadNextUsersPosts:
      return .concat([
        .just(.setLoading(true)),
        postManager
          .rxSearchFollowUserPost(
            followIds: followUser ?? [],
            from: self.currentState.posts.count,
            to: self.currentState.posts.count + 10)
          .map { .appendPosts($0) },
        .just(.setLoading(false))
      ])
    case .setPostType(let type):
      return .just(.setPostType(type))
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    switch mutation {
    case .setLoading(let isLoading):
      return state.with {
        $0.isLoading = isLoading
      }
    case .setPosts(let posts):
      return state.with {
        $0.posts = posts
      }
    case .appendPosts(let posts):
      return state.with {
        $0.posts.append(contentsOf: posts)
      }
    case .setPostType(let type):
      return state.with {
        $0.postType = type
      }
    }
  }

  func transform(state: Observable<State>) -> Observable<State> {
    state.observe(on: MainScheduler.instance)
  }
}

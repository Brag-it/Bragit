//
//  HomeReactor.swift
//  Bragit
//
//  Created by seongjun cho on 8/21/25.
//

import Foundation

import ReactorKit
import Then
import Dependencies

class HomeReactor: Reactor {
  var initialState: State
  @Dependency(\.postManager) var postManager
  private let disposeBag = DisposeBag()

  enum Action {
    case loadPosts
    case loadNextPosts
  }

  enum Mutation {
    case setLoading(Bool)
    case setPosts([Post])
    case appendPosts([Post])
  }

  struct State: Then {
    var posts: [Post] = []
    var isLoading: Bool = false
  }

  init() {
    self.initialState = State()
  }

  func mutate(action: Action) -> Observable<Mutation> {
    if currentState.isLoading {
      return .empty()
    }
    switch action {
    case .loadPosts:
      return .concat([
        .just(.setLoading(true)),
        postManager
          .rxFetchMainFeedData(
            from: 0,
            to: 10)
          .map { .setPosts($0) },
        .just(.setLoading(false))
      ])
    case .loadNextPosts:
      return .concat([
        .just(.setLoading(true)),
        postManager
          .rxFetchMainFeedData(
            from: self.currentState.posts.count,
            to: self.currentState.posts.count + 10)
          .map { .appendPosts($0) },
        .just(.setLoading(false))
      ])
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
    }
  }

  func transform(state: Observable<State>) -> Observable<State> {
    state.observe(on: MainScheduler.instance)
  }
}

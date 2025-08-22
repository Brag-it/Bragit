//
//  HomeReactor.swift
//  Bragit
//
//  Created by seongjun cho on 8/21/25.
//

import ReactorKit
import Foundation

class HomeReactor: Reactor {
  var initialState: State
  private let postManager: PostManagerProtocol
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

  struct State {
    var posts: [Post] = []
    var isLoading: Bool = false
  }

  init(postManager: PostManagerProtocol) {
    self.initialState = State()
    self.postManager = postManager
  }

  func mutate(action: Action) -> Observable<Mutation> {
    if currentState.isLoading {
        return .empty()
    }
    switch action {
    case .loadPosts:
      return .concat([
        .just(.setLoading(true)),
        Single.create { [weak self] single in
          guard let self = self else {
            single(.success(.appendPosts([])))
            return Disposables.create()
          }
          Task {
            do {
              let posts = try await self.postManager.fetchMainFeedData(from: 0, to: 10)
              single(.success(.setPosts(posts)))
            } catch {
              single(.failure(error))
            }
          }
          return Disposables.create()
        }.asObservable(),
        .just(.setLoading(false))
      ])
    case .loadNextPosts:
      return .concat([
        .just(.setLoading(true)),
        Single.create { [weak self] single in
          guard let self = self else {
            single(.success(.appendPosts([])))
            return Disposables.create()
          }

          Task {
            do {
              let posts = try await self.postManager
                .fetchMainFeedData(from: self.initialState.posts.count,
                                   to: self.initialState.posts.count + 10
                )
              single(.success(.setPosts(posts)))
            } catch {
              single(.failure(error))
            }
          }
          return Disposables.create()
        }.asObservable(),
        .just(.setLoading(false))
      ])
    }
  }
}

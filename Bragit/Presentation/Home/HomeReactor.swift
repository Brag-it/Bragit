//
//  HomeReactor.swift
//  Bragit
//
//  Created by seongjun cho on 8/21/25.
//

import Foundation

import ReactorKit
import RxFlow
import RxRelay
import Then
import Dependencies

class HomeReactor: Reactor, Stepper {
  var initialState: State
  @Dependency(\.postManager) var postManager
  @Dependency(\.userManager) var userManager
  @LocalStorage(location: .followUser) var followUser: [String]?
  let steps = PublishRelay<Step>()
  private let disposeBag = DisposeBag()

  enum Action {
    case loadPosts
    case loadNextPosts
    case followButtonTapped(Post)
    case didTapPost(Post)
    case goToTagDetail(Tag)
    case refresh
  }

  enum Mutation {
    case setLoading(Bool)
    case setPosts([Post])
    case appendPosts([Post])
    case setPostsToReconfigure([Post]?)
  }

  struct State: Then {
    var posts: [Post] = []
    var isLoading: Bool = false
    var postsToReconfigure: [Post]?
  }

  init() {
    self.initialState = State()
  }

  func mutate(action: Action) -> Observable<Mutation> {
    if currentState.isLoading {
      return .empty()
    }
    switch action {
    case .refresh:
      return .concat([
      .just(.setLoading(true)),
      postManager
        .rxFetchMainFeedData(
          from: 0,
          to: 10)
        .map { .setPosts($0) },
      .just(.setLoading(false))
    ])
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
    case .followButtonTapped(let post):
      return Observable.create { [weak self] observer in
        guard let self = self else {
          observer.onCompleted()
          return Disposables.create()
        }

        Task {
          do {
            let authorId = post.author?.id ?? ""
            if self.followUser?.contains(authorId) == true {
              self.followUser = self.followUser?.filter { $0 != authorId }
              try await self.userManager.unfollowUser(id: authorId)
            } else {
              self.followUser = (self.followUser ?? []) + [authorId]
              try await self.userManager.followUser(id: authorId)
            }
            observer.onNext(.setPostsToReconfigure(self.currentState.posts.filter {
              $0.author?.id == post.author?.id
            }))
            observer.onNext(.setPostsToReconfigure(nil))
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
    case .goToTagDetail(let tag):
      self.steps.accept(AppStep.tagInform(tag))
      return .empty()
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
    case .setPostsToReconfigure(let posts):
      return state.with {
        $0.postsToReconfigure = posts
      }
    }
  }

  func transform(state: Observable<State>) -> Observable<State> {
    state.observe(on: MainScheduler.instance)
  }
}

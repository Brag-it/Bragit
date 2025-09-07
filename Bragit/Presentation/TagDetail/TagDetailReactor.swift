//
//  TagDetailReactor.swift
//  Bragit
//
//  Created by seongjun cho on 9/4/25.
//

import ReactorKit
import RxSwift
import RxFlow
import RxRelay
import Then
import Dependencies

class TagDetailReactor: Reactor, Stepper {
  var initialState: State
  let steps = PublishRelay<Step>()
  let tag: Tag
  @Dependency(\.postManager) var postManager
  @Dependency(\.userManager) var userManager

  private let disposeBag = DisposeBag()
  // 사용자 액션 정의 (사용자의 의도)
  enum Action {
    case backButtonTap
    case setTagInform
    case followDidTap(Post)
    case tagFollowDidTap
  }

  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case setTagName(String)
    case setIsFollow(Bool)
    case setPostCount(Int)
    case setPosts([Post])
    case setPostsToReconfigure([Post])
  }

  // View의 상태 정의 (현재 View의 상태값)
  struct State: Then {
    var tagName: String = ""
    var isFollow: Bool = false
    var postCount: Int = 0
    var posts: [Post] = []
    var postsToReconfigure: [Post] = []
  }

  init(tag: Tag) {
    self.tag = tag
    self.initialState = State()
  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .backButtonTap:
      steps.accept(AppStep.pop)
      return .empty()
    case .setTagInform:
      @LocalStorage(location: .favoriteTags) var favoriteTags: [Tag]?
      let isFollow = favoriteTags?.contains { tag.id == $0.id } ?? false

      return postManager.rxSearchFeed(tagIDs: [tag.id], from: 0, to: 10)
        .flatMap { posts -> Observable<Mutation> in
          return .from([
            .setTagName(self.tag.tag),
            .setIsFollow(isFollow),
            .setPostCount(posts.count),
            .setPosts(posts)]
          )
        }
    case .followDidTap(let post):
      @LocalStorage(location: .followUser) var followUser: [String]?
      return Observable.create { [weak self] observer in
        guard let self = self else {
          observer.onCompleted()
          return Disposables.create()
        }

        Task {
          do {
            let authorId = post.author?.id ?? ""
            if followUser?.contains(authorId) == true {
              followUser = followUser?.filter { $0 != authorId }
              try await self.userManager.unfollowUser(id: authorId)
            } else {
              followUser = (followUser ?? []) + [authorId]
              try await self.userManager.followUser(id: authorId)
            }
            observer.onNext(.setPostsToReconfigure(self.currentState.posts.filter {
              $0.author?.id == post.author?.id
            }))
            observer.onNext(.setPostsToReconfigure([]))
            observer.onCompleted()
          } catch {
            observer.onError(error)
          }
        }
        return Disposables.create()
      }
    case .tagFollowDidTap:
      @LocalStorage(location: .favoriteTags) var favoriteTags: [Tag]?
      if currentState.isFollow {
        favoriteTags = favoriteTags?.filter { $0.id != tag.id }
      } else {
        favoriteTags = (favoriteTags ?? []) + [tag]
      }
      return .just(.setIsFollow(!currentState.isFollow))
    }
  }

  // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
  // 상태 변화 신호 → 실제 상태 반영
  func reduce(state: State, mutation: Mutation) -> State {
    switch mutation {
    case .setPosts(let posts):
      return state.with { $0.posts = posts }
    case .setIsFollow(let isFollow):
      return state.with { $0.isFollow = isFollow }
    case .setPostCount(let postCount):
      return state.with { $0.postCount = postCount }
    case .setTagName(let tagName):
      return state.with { $0.tagName = tagName }
    case .setPostsToReconfigure(let posts):
      return state.with {
        $0.postsToReconfigure = posts
      }
    }
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }
}

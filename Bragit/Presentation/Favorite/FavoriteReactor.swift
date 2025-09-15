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
  @Dependency(\.tagManager) var tagManager
  @Dependency(\.userManager) var userManager
  private let disposeBag = DisposeBag()
  let steps = PublishRelay<Step>()
  let doReload = PublishRelay<Void>()

  enum PostType: Hashable {
    case tag([Tag])
    case user([User])
    case emptyTag([Tag])
    case emptyUser
  }

  enum Action {
    case loadNextPosts
    case tagTapped(Tag?)
    case userTapped(User)
    case menuTapped(Int)
    case followButtonTapped(Post)
    case goToTagDetail(Tag)
    case refresh
    case searchTapped
    case didTapPost(Post)
    case userProfileTapped(Post)
  }

  enum Mutation {
    case setLoading(Bool)
    case setPosts([Post])
    case appendPosts([Post])
    case setPostType(PostType)
    case setSelectedTag(Tag?)
    case setPostsToReconfigure([Post]?)
    case doReload
  }

  struct State: Then {
    var posts: [Post] = []
    var isLoading: Bool = false
    var postType: PostType = .emptyTag([]) {
      didSet {
        print(self.postType)
      }
    }
    var selectedTag: Tag?
    var hasNexPage: Bool = false
    var postsToReconfigure: [Post]?
  }

  init() {
    self.initialState = State()
  }

  // swiftlint:disable cyclomatic_complexity
  func mutate(action: Action) -> Observable<Mutation> {
    print(action)

    switch action {
    case .loadNextPosts:
      let postCount = self.currentState.posts.count
      guard currentState.isLoading == false, currentState.hasNexPage else {
        return .empty()
      }
      switch self.currentState.postType {
      case .tag(let tags):
        return .concat([
          .just(.setLoading(true)),
          postManager.rxSearchFeed(tagIDs: tags.map { $0.id }, from: postCount, to: postCount + 10)
            .map { .appendPosts($0) },
          .just(.setLoading(false))
        ])
      case .emptyTag:
        return self.tagManager.rxFetchPopularTags().flatMap { [weak self] popularTags -> Observable<Mutation> in
          guard let self = self else { return .empty() }

          return .concat([
            .just(.setLoading(true)),
            postManager.rxSearchFeed(tagIDs: popularTags.map { $0.id }, from: postCount, to: postCount + 10)
              .map { .appendPosts($0) },
            .just(.setLoading(false))
          ])
        }
      case .user(let users):
        return .concat([
          .just(.setLoading(true)),
          postManager.rxSearchFollowUserPost(followIds: users.map { $0.id }, from: postCount, to: postCount + 10)
            .map { .appendPosts($0) },
          .just(.setLoading(false))
        ])
      case .emptyUser:
        return .concat([
          .just(.setLoading(true)),
          postManager.rxFetchPopularPost(from: postCount, to: postCount + 10)
            .map { .appendPosts($0) },
          .just(.setLoading(false))
        ])
      }
    case .tagTapped(let tag):
      @LocalStorage(location: .favoriteTags) var favoriteTags: [Tag]?
      let stream = Observable.deferred { [weak self] () -> Observable<Mutation> in
        guard let self = self else { return .empty() }
        if favoriteTags == nil || favoriteTags!.isEmpty {
          return self.tagManager.rxFetchPopularTags().flatMap { [weak self] tags -> Observable<Mutation> in
            guard let self = self else { return .empty() }
            return self.rxSetPost(postType: .emptyTag(tags))
          }
        } else {
          let postType: PostType = (tag == nil) ? .tag(favoriteTags!) : .tag([tag!])
          return self.rxSetPost(postType: postType)
        }
      }

      return .concat([
        .just(.setLoading(true)),
        .just(.setSelectedTag(tag)),
        stream,
        .just(.setLoading(false))
      ])
    case .menuTapped(let index):
      @LocalStorage(location: .favoriteTags) var favoriteTags: [Tag]?
      @LocalStorage(location: .followUser) var followUser: [String]?

      switch index {
        // 0번 메뉴 태그
      case 0:
        if favoriteTags == nil || favoriteTags!.isEmpty {
          // 관심 태그가 없을 경우, 인기 태그를 가져옴
          return self.tagManager.rxFetchPopularTags().flatMap { [weak self] popularTags -> Observable<Mutation> in
            guard let self = self else { return .empty() }

            return .concat([
              .just(.setLoading(true)),
              .just(.setPostType(.emptyTag(popularTags))),
              rxSetPost(postType: .emptyTag(popularTags)),
              .just(.doReload),
              .just(.setLoading(false))
            ])
          }
        } else {
          // 관심 태그가 있을 경우
          // 선택되어 있는 태그가 있던경우
          if currentState.selectedTag != nil {
            return .concat([
              .just(.setLoading(true)),
              .just(.setPostType(.tag(favoriteTags ?? []))),
              rxSetPost(postType: .tag([currentState.selectedTag!])),
              .just(.doReload),
              .just(.setLoading(false))
            ])
          } else {
            return .concat([
              .just(.setLoading(true)),
              .just(.setPostType(.tag(favoriteTags ?? []))),
              rxSetPost(postType: .tag(favoriteTags ?? [])),
              .just(.doReload),
              .just(.setLoading(false))
            ])
          }
        }
      case 1: // "사용자" 메뉴 탭
        if followUser == nil || followUser!.isEmpty {
          // 팔로우한 사용자가 없는 경우
          return .concat([
            .just(.setLoading(true)),
            rxPostTypeChangeToEmptyUser(),
            .just(.doReload),
            .just(.setLoading(false))
          ])
        } else {
          // 팔로우한 사용자가 있을 경우
          return .concat([
            .just(.setLoading(true)),
            rxPostTypeChangeToUser(),
            .just(.doReload),
            .just(.setLoading(false))
          ])
        }

      default:
        return .empty()
      }
    case .followButtonTapped(let post):
      let authorId = post.author?.id ?? ""
      guard currentState.isLoading == false else {
        return .empty()
      }
      @LocalStorage(location: .followUser) var followUser: [String]?

      // 언팔로우인 경우
      if followUser?.contains(authorId) == true {
        followUser = followUser?.filter { $0 != authorId }
        let followUser = followUser ?? []

        return .concat([
          .just(.setLoading(true)),
          userManager.rxUnfollowUser(id: authorId) // 서버에 언팔로우
            .andThen(Observable.deferred { [weak self] () -> Observable<Mutation> in
              guard let self = self else { return .empty() }
              if followUser.isEmpty { // 팔로워가 없는 경우
                return self.rxPostTypeChangeToEmptyUser() // emptyUser로 전환
              } else {
                return .empty()
              }
            }),
          .just(.setPostsToReconfigure(self.currentState.posts.filter { // 포스트 갱신
            $0.author?.id == post.author?.id
          })),
          .just(.setPostsToReconfigure(nil)),
          .just(.setLoading(false))
        ])
      } else { // 팔로우인 경우
        followUser = (followUser ?? []) + [authorId]

        return .concat([
          .just(.setLoading(true)),
          userManager.rxFollowUser(id: authorId) // 서버에 팔로우
            .andThen(Observable.deferred { [weak self] () -> Observable<Mutation> in
              guard let self = self else { return .empty() }
              if (followUser ?? []).count == 1 { // 팔로워가 없다가 생긴 경우
                return self.rxPostTypeChangeToUser() // User로 전환
              } else {
                return .empty()
              }
            }),
          .just(.setPostsToReconfigure(self.currentState.posts.filter { // 포스트 갱신
            $0.author?.id == post.author?.id
          })),
          .just(.setPostsToReconfigure(nil)),
          .just(.setLoading(false))
        ])
      }
    case .goToTagDetail(let tag):
      self.steps.accept(AppStep.tagInform(tag))
      return .empty()
    case .refresh:
      return .concat([
        rxSetPost(postType: currentState.postType),
        .just(.doReload)
      ])
    case .searchTapped:
      steps.accept(AppStep.searchFeed)
      return .empty()
    case .didTapPost(let post):
      self.steps.accept(AppStep.feedDetail(post: post))
      return .empty()
    case .userProfileTapped(let post):
      guard let authorId = post.author?.id, !authorId.isEmpty else {
        return .empty()
      }

      return userManager
        .rxfetchUsersBy(ids: [authorId])
        .compactMap { $0.first }
        .do { [weak self] user in
          self?.steps.accept(AppStep.userProfile(user: user))
        }
        .flatMap { _ in Observable<Mutation>.empty() }
    case .userTapped(let user):
      steps.accept(AppStep.userProfile(user: user))
      return .empty()
    }
  }
  // swiftlint:enable cyclomatic_complexity

  func reduce(state: State, mutation: Mutation) -> State {
    switch mutation {
    case .setLoading(let isLoading):
      return state.with {
        $0.isLoading = isLoading
      }
    case .setPosts(let posts):
      return state.with {
        $0.hasNexPage = posts.count >= 10
        $0.posts = posts
      }
    case .appendPosts(let posts):
      return state.with {
        $0.hasNexPage = posts.count >= 10
        $0.posts.append(contentsOf: posts)
      }
    case .setPostType(let type):
      return state.with {
        $0.postType = type
      }
    case .setSelectedTag(let tag):
      return state.with {
        $0.selectedTag = tag
      }
    case .setPostsToReconfigure(let posts):
      return state.with {
        $0.postsToReconfigure = posts
      }
    case .doReload:
      doReload.accept(())
      return state
    }
  }

  func transform(state: Observable<State>) -> Observable<State> {
    state.observe(on: MainScheduler.instance)
  }

  private func rxPostTypeChangeToEmptyUser() -> Observable<Mutation> {
    // 팔로우한 사용자가 없을 경우, 인기 게시물을 가져옴
    let setPopularPostStream = self.postManager.rxFetchPopularPost(from: 0, to: 10)
      .map { Mutation.setPosts($0) }

    return .concat([.just(.setPostType(.emptyUser)), setPopularPostStream])
  }

  private func rxPostTypeChangeToUser() -> Observable<Mutation> {
    @LocalStorage(location: .followUser) var followUser: [String]?
    let postManager = self.postManager

    // ID들로 유저 정보 가져오기
    return self.userManager.rxfetchUsersBy(ids: followUser ?? [])
      .flatMap { users -> Observable<Mutation> in
        // 팔로우 유저의 아이디들로 게시글 가져옴
        let postsStream = postManager
          .rxSearchFollowUserPost(followIds: users.map { $0.id }, from: 0, to: 10)
          .map { Mutation.setPosts($0) }

        return .concat([
          .just(.setPostType(.user(users))),
          postsStream
        ])
      }
  }

  private func rxSetPost(postType: PostType) -> Observable<Mutation> {
    switch postType {
    case .tag(let tags), .emptyTag(let tags):
      let postsStream = {
        if self.currentState.selectedTag != nil {
          self.postManager.rxSearchFeed(tagIDs: [self.currentState.selectedTag!.id], from: 0, to: 10)
            .map { Mutation.setPosts($0) }
        } else {
          self.postManager.rxSearchFeed(tagIDs: tags.map { $0.id }, from: 0, to: 10)
            .map { Mutation.setPosts($0) }
        }
      }()

      return .concat([
        .just(.setLoading(true)),
        postsStream,
        .just(.setLoading(false))
      ])
    case .user:
      return .concat([
        .just(.setLoading(true)),
        rxPostTypeChangeToUser(),
        .just(.setLoading(false))
      ])
    case .emptyUser:
      return .concat([
        .just(.setLoading(true)),
        rxPostTypeChangeToEmptyUser(),
        .just(.setLoading(false))
      ])
    }
  }
}

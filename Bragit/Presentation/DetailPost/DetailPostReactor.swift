//
//  DetailPostReactor.swift
//  Bragit
//
//  Created by 이태윤 on 9/4/25.
//
import UIKit

import ReactorKit
import RxSwift
import RxFlow
import RxRelay
import Dependencies
import Loaf

class DetailPostReactor: Reactor, Stepper {
  var initialState: State
  @Dependency(\.userManager) var userManager
  @Dependency(\.postManager) var postManager
  @LocalStorage(location: .likePosts) var likePosts: [String]?
  @LocalStorage(location: .nowUser) var nowUser: String?
  @LocalStorage(location: .followUser) var followUser: [String]?

  let post: Post
  let steps = PublishRelay<Step>()
  private let disposeBag = DisposeBag()

  // 사용자 액션 정의 (사용자의 의도)
  enum Action {
    case didTapBack
    case didTapLike
    case didTapComment
    case didTapFollow
    case didTapEdit
    case didTapReport
    case didTapDelete
    case didTapUserProfile
    case showToast(ToastPurpose)
  }

  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case setIsLike(Bool, Int)
    case setIsFollowed(Bool)
    case setLoading(Bool)
    case setDeleted
    case setError(Error)
    case setToast(ToastEvent?)
  }

  // View의 상태 정의 (현재 View의 상태값)
  struct State {
    let title: String               // 제목
    let content: NSAttributedString // 내용
    let nickName: String            // 게시글 작성자 닉네임
    let profileImage: String?       // 프로필 사진
    var isLoading: Bool = false     // 로딩 표시
    let viewer: Bool                // 작성자 본인판별
    var isLiked: Bool               // 좋아요 눌렀는지
    var likeCount: Int              // 좋아요 수
    var isfollowed: Bool            // 팔로우 여부
    var withdrewUser: Bool          // 탈퇴유저 체크
    @Pulse var toast: ToastEvent?  // 삭제/신고/에러 토스트 이벤트
  }

  init(post: Post) {
    @LocalStorage(location: .likePosts) var likePosts: [String]?
    @LocalStorage(location: .nowUser) var nowUser: String?
    @LocalStorage(location: .followUser) var followUser: [String]?
    self.initialState = State(
      title: post.title,
      content: DetailPostReactor.unarchivedContent(content: post.content),
      nickName: post.author?.nickname ?? "탈퇴한 유저",
      profileImage: post.author?.profile ?? nil,
      viewer: post.author?.id.lowercased() == nowUser?.lowercased(),
      isLiked: likePosts?.contains { $0 == post.id.uuidString } ?? false,
      likeCount: post.like,
      isfollowed: followUser?.contains { $0 == post.author?.id } ?? false,
      withdrewUser: post.author?.nickname == nil
    )
    self.post = post

  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  // swiftlint:disable cyclomatic_complexity
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .didTapBack:
      steps.accept(AppStep.pop)
      return .empty()

    case .didTapLike:
      // 게시글 단위로 좋아요 토글
      let postId = post.id.uuidString
      let willLike = !currentState.isLiked

      if willLike {
        var ids = likePosts ?? []
        if !ids.contains(postId) { ids.append(postId) }
        likePosts = ids
      } else {
        if var ids = likePosts {
          ids.removeAll { $0 == postId }
          likePosts = ids
        }
      }

      let optimisticCount = max(0, currentState.likeCount + (willLike ? 1 : -1))
      let optimistic = Observable.just(Mutation.setIsLike(willLike, optimisticCount))
      let sync = postManager.rxIncrementLike(postId: postId, delta: willLike ? 1 : -1)
        .map { serverCount in
          // 최신 값으로 보정
          Mutation.setIsLike(willLike, serverCount)
        }
        .catch { [weak self] error in
          // 실패 시 롤백
          guard let self = self else { return .empty() }
          if willLike {
            // 되돌려 제거
            if var ids = self.likePosts {
              ids.removeAll { $0 == postId }
              self.likePosts = ids
            }
          } else {
            // 되돌려 추가
            var ids = self.likePosts ?? []
            if !ids.contains(postId) { ids.append(postId) }
            self.likePosts = ids
          }
          let rollbackCount = max(0, optimisticCount + (willLike ? -1 : +1))
          print("inc_post_like RPC 실패:", error.localizedDescription)
          return .just(.setIsLike(!willLike, rollbackCount))
        }
      return optimistic.concat(sync)

    case .didTapComment:
      steps.accept(AppStep.comment(id: post.id))
      return .empty()

    case .didTapFollow:
      return Observable.create { [weak self] observer in
        guard let self = self else {
          observer.onCompleted()
          return Disposables.create()
        }

        Task {
          do {
            // 작성자 ID 없으면 종료
            guard let authorId = self.post.author?.id, !authorId.isEmpty else {
              observer.onCompleted()
              return
            }
            // 현재 로컬 팔로우 목록
            var followed = self.followUser ?? []

            // 토글 판단
            let willFollow: Bool
            if followed.contains(authorId) {
              // 언팔로우
              followed.removeAll { $0 == authorId }
              self.followUser = followed
              try await self.userManager.unfollowUser(id: authorId)
              willFollow = false
            } else {
              // 팔로우
              followed.append(authorId)
              self.followUser = followed
              try await self.userManager.followUser(id: authorId)
              willFollow = true
            }
            // 화면 상태 갱신
            observer.onNext(.setIsFollowed(willFollow))
            observer.onCompleted()
          } catch {
            observer.onError(error)
          }
        }

        return Disposables.create()
      }
    case .didTapEdit:
      let post = PostUpdate(id: post.id, title: currentState.title, content: currentState.content)
      steps.accept(AppStep.updateFeed(post: post))
      return .empty()

    case .didTapReport:
      return postManager.rxIncrementReports(postId: post.id)
        .map { _ in Mutation.setToast(ToastEvent(purpose: .reported)) }
        .catch { error in
          .just(.setToast(ToastEvent(purpose: .error(error.localizedDescription))))
        }

    case .didTapDelete:
      return Observable.concat([
        .just(.setLoading(true)),
        postManager.rxDeletePost(postId: post.id.uuidString)
          .flatMap { _ in
            Observable.from([
              Mutation.setToast(ToastEvent(purpose: .deleted)),
              Mutation.setDeleted
            ])
          }
          .catch { error in
            return .just(.setToast(ToastEvent(purpose: .error(error.localizedDescription))))
          },
        .just(.setLoading(false))
      ])

    case .showToast(let purpose):
      return .just(.setToast(ToastEvent(purpose: purpose)))

    case .didTapUserProfile:
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
        .catch { error in
          print("fetch user failed:", error)
          return .empty()
        }
    }
  }
  // swiftlint:enable cyclomatic_complexity

  // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
  // 상태 변화 신호 → 실제 상태 반영
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setIsLike(let isLike, let count):
      newState.isLiked = isLike
      newState.likeCount = count

    case .setIsFollowed(let isFollowed):
      newState.isfollowed = isFollowed

    case .setLoading(let isLoading):
      newState.isLoading = isLoading

    case .setDeleted:
      steps.accept(AppStep.pop)
      return state

    case .setError(let error):
      return print(error) == () ? state : state

    case let .setToast(event):
      newState.toast = event
    }

    return newState
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }

  // 복원
  static func unarchivedContent(content: String) -> NSAttributedString {
    guard let data = Data(base64Encoded: content) else {
      return NSAttributedString(string: content) // fallback
    }
    do {
      return try NSKeyedUnarchiver.unarchivedObject(
        ofClass: NSAttributedString.self,
        from: data
      ) ?? NSAttributedString()
    } catch {
      print("Unarchive 실패:", error.localizedDescription)
      return NSAttributedString(string: content)
    }
  }
}

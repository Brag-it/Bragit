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

class DetailPostReactor: Reactor, Stepper {
  var initialState: State
  @Dependency(\.userManager) var userManager
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
  }

  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case setIsLike(Bool, Int)
    case setIsFollowed(Bool)
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
  }

  init(post: Post) {
    @LocalStorage(location: .likePosts) var likePosts: [String]?
    @LocalStorage(location: .nowUser) var nowUser: String?
    @LocalStorage(location: .followUser) var followUser: [String]?
    self.initialState = State(
      title: post.title,
      content: DetailPostReactor.unarchivedContent(content: post.content),
      nickName: post.author?.nickname ?? "탈퇴한 유저 입니다",
      profileImage: post.author?.profile ?? nil,
      viewer: post.author?.id == nowUser,
      isLiked: likePosts?.contains { $0 == post.id.uuidString } ?? false,
      likeCount: post.like,
      isfollowed: followUser?.contains { $0 == post.author?.id } ?? false
    )
    self.post = post
  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .didTapBack:
      steps.accept(AppStep.pop)
      return .empty()

    case .didTapLike:
      var count = currentState.likeCount
      if currentState.isLiked == false {
        likePosts?.append(post.id.uuidString)
        count += 1
      } else {
        likePosts?.removeAll { $0 == post.author?.id }
        count -= 1
      }
      return .just(.setIsLike(!currentState.isLiked, count))

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
    }
  }
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

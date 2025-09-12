//
//  CommentReactor.swift
//  Bragit
//
//  Created by luca on 9/4/25.
//

import Foundation

import Dependencies
import ReactorKit
import RxFlow
import RxRelay
import RxSwift
import Supabase

final class CommentReactor: Reactor, Stepper {
  let initialState: State
  private let postId: UUID
  @Dependency(\.supabase) var supabase
  @Dependency(\.userManager) var userManager
  let steps = PublishRelay<Step>()

  @LocalStorage(location: .nowUser) private var storedUserId: String?

  // MARK: Reactor
  enum Action {
    case refresh
    case didTapBack
    case sendComment(String)
    case didTapKebab(IndexPath)
    case deleteComment(IndexPath)
    case reportComment(IndexPath)
    case didTapUserProfile(String)
  }

  enum Mutation {
    case setLoading(Bool)
    case setComments([CommentRow])
    case setError(String?)
    case setCommentSent(Bool)
    case setCurrentUserId(String?)
  }

  struct State {
    var isLoading: Bool = false
    var comments: [CommentRow] = []
    var errorMessage: String?
    let viewer: Bool
    var commentSent: Bool = false
    var currentUserId: String?
  }

  // MARK: Model for decoding Comment rows
  struct CommentRow: Codable, Equatable, Hashable {
    struct CommentUser: Codable, Equatable, Hashable {
      let nickname: String?
      let profile: String?
    }

    let id: UUID
    let postId: UUID
    let content: String
    let date: Date
    let commenterId: String?
    let user: CommentUser?
    let reports: Int?

    enum CodingKeys: String, CodingKey {
      case id
      case postId = "post_id"
      case content
      case date
      case commenterId = "commenter_id"
      case user = "User_Info"
      case reports
    }
  }

  init(postId: UUID, viewer: Bool = false) {
    self.postId = postId
    let currentUser = LocalStorage<String?>(location: .nowUser).wrappedValue
    var state = State(viewer: viewer)
    state.currentUserId = currentUser
    self.initialState = state
  }

  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .refresh:
      return mutateRefresh()
    case .didTapBack:
      return mutateBack()
    case .sendComment(let content):
      return mutateSendComment(content: content)
    case .didTapKebab:
      return .empty()
    case .deleteComment(let indexPath):
      return mutateDeleteComment(indexPath: indexPath)
    case .reportComment(let indexPath):
      return mutateReportComment(indexPath: indexPath)
    case .didTapUserProfile(let userId):
      guard userId.isEmpty == false else { return .empty() }
      return userManager
        .rxfetchUsersBy(ids: [userId])
        .compactMap { $0.first }
        .do { [weak self] user in
          self?.steps.accept(AppStep.userProfile(user: user))
        }
        .flatMap { _ in Observable<Mutation>.empty() }
    }
  }

  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .setLoading(let loading):
      newState.isLoading = loading
      if loading { newState.errorMessage = nil }
    case .setComments(let rows):
      newState.comments = rows
    case .setError(let message):
      newState.errorMessage = message
    case .setCommentSent(let sent):
      newState.commentSent = sent
    case .setCurrentUserId(let id):
      newState.currentUserId = id
    }
    return newState
  }

  func transform(state: Observable<State>) -> Observable<State> {
    state.observe(on: MainScheduler.instance)
  }

  // 최신순 기준으로 IndexPath에 해당하는 댓글 반환
  private func comment(atSortedIndexPath indexPath: IndexPath) -> CommentRow? {
    let sorted = currentState.comments.sorted { $0.date > $1.date }
    guard indexPath.row >= 0, indexPath.row < sorted.count else { return nil }
    return sorted[indexPath.row]
  }

  // MARK: - Action handlers
  private func mutateRefresh() -> Observable<Mutation> {
    let start = Observable.just(Mutation.setLoading(true))
    let setUser = Observable.just(Mutation.setCurrentUserId(storedUserId))
    let request = rxFetchComments(postId: postId)
      .map { Mutation.setComments($0) as Mutation }
      .catch { error in
        let msg = (error as NSError).localizedDescription
        return .just(.setError(msg))
      }
    let end = Observable.just(Mutation.setLoading(false))
    return .concat([start, setUser, request, end])
  }

  private func mutateBack() -> Observable<Mutation> {
    steps.accept(AppStep.pop)
    return .empty()
  }

  private func mutateSendComment(content: String) -> Observable<Mutation> {
    guard currentState.isLoading == false else { return .empty() }

    let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedContent.isEmpty else { return .empty() }

    let start = Observable.just(Mutation.setLoading(true))
    let send = rxSendComment(content: trimmedContent)
      .flatMap { [weak self] _ -> Observable<Mutation> in
        guard let self else { return .empty() }
        return self.rxFetchComments(postId: self.postId)
          .map { Mutation.setComments($0) }
          .catch { error in
            let msg = (error as NSError).localizedDescription
            return .just(.setError(msg))
          }
      }
    let setSent = Observable.just(Mutation.setCommentSent(true))
    let resetSent = Observable.just(Mutation.setCommentSent(false))
      .delay(.milliseconds(100), scheduler: MainScheduler.instance)
    let end = Observable.just(Mutation.setLoading(false))

    return .concat([start, send, setSent, resetSent, end])
  }

  private func mutateDeleteComment(indexPath: IndexPath) -> Observable<Mutation> {
    guard currentState.isLoading == false else { return .empty() }

    guard let target = comment(atSortedIndexPath: indexPath) else {
      return .just(.setError("[Delete Comment] 인덱스 에러"))
    }

    if let ownerId = target.commenterId,
      let currentUserId = storedUserId,
      ownerId != currentUserId {
      return .just(.setError("[Delete Comment] 삭제 권한 없음"))
    }

    let start = Observable.just(Mutation.setLoading(true))
    let delete = rxDeleteComment(commentId: target.id)
    let refresh = rxFetchComments(postId: postId)
      .map { Mutation.setComments($0) as Mutation }
      .catch { error in
        let message = (error as NSError).localizedDescription
        return .just(.setError(message))
      }
    let end = Observable.just(Mutation.setLoading(false))

    return .concat([
      start,
      delete.map { _ in Mutation.setError(nil) },
      refresh,
      end
    ])
  }

  private func mutateReportComment(indexPath: IndexPath) -> Observable<Mutation> {
    guard currentState.isLoading == false else { return .empty() }

    guard let target = comment(atSortedIndexPath: indexPath) else {
      return .just(.setError("[Report Comment] 인덱스 에러"))
    }

    let start = Observable.just(Mutation.setLoading(true))
    let report = rxReportComment(commentId: target.id)
      .map { _ in Mutation.setError(nil) as Mutation }
      .catch { error in
        let message = (error as NSError).localizedDescription
        return .just(Mutation.setError(message))
      }
    let end = Observable.just(Mutation.setLoading(false))

    return .concat([start, report, end])
  }

  // MARK: Data
  private func rxFetchComments(postId: UUID) -> Observable<[CommentRow]> {
    .create { [weak self] observer in
      guard let self else {
        observer.onCompleted()
        return Disposables.create()
      }
      let task = Task {
        do {
          let rows: [CommentRow] = try await self.supabase
            .from("Comment")
            .select("id, post_id, content, date, commenter_id, reports, User_Info!left(nickname, profile)")
            .eq("post_id", value: postId)
            .order("date", ascending: true)
            .execute()
            .value

          observer.onNext(rows)
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }
      return Disposables.create { task.cancel() }
    }
  }

  private func rxSendComment(content: String) -> Observable<Void> {
    .create { [weak self] observer in
      guard let self else {
        observer.onCompleted()
        return Disposables.create()
      }

      let task = Task {
        do {
          guard let userId = self.storedUserId, userId.isEmpty == false else {
            throw NSError(
              domain: "CommentReactor",
              code: -1,
              userInfo: [NSLocalizedDescriptionKey: "로그인 필요"]
            )
          }

          let newCommentId = UUID()
          let currentDate = Date()

          let newComment = Comment(
            id: newCommentId,
            postId: self.postId,
            commenterId: userId,
            content: content,
            date: currentDate
          )

          try await self.supabase
            .from("Comment")
            .insert(newComment)
            .execute()

          observer.onNext(())
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }
      return Disposables.create { task.cancel() }
    }
  }

  private func rxDeleteComment(commentId: UUID) -> Observable<Void> {
    .create { [weak self] observer in
      guard let self else {
        observer.onCompleted()
        return Disposables.create()
      }

      let task = Task {
        do {
          try await self.supabase
            .from("Comment")
            .delete()
            .eq("id", value: commentId)
            .execute()
          observer.onNext(())
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }
      return Disposables.create { task.cancel() }
    }
  }

  // report +1 (safe two-step increment to avoid SQL literal errors)
  private func rxReportComment(commentId: UUID) -> Observable<Void> {
    struct Row: Codable { let reports: Int? }

    return .create { [weak self] observer in
      guard let self else {
        observer.onCompleted()
        return Disposables.create()
      }

      let task = Task {
        do {
          // 현재 값 조회
          let current: Row = try await self.supabase
            .from("Comment")
            .select("reports")
            .eq("id", value: commentId)
            .single()
            .execute()
            .value

          let newValue = (current.reports ?? 0) + 1

          // 증가된 값으로 업데이트
          try await self.supabase
            .from("Comment")
            .update(["reports": newValue])
            .eq("id", value: commentId)
            .execute()

          observer.onNext(())
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }
      return Disposables.create { task.cancel() }
    }
  }
}

private struct SQLLiteral: Encodable {
  let raw: String
  init(_ raw: String) { self.raw = raw }
  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(raw)
  }
}

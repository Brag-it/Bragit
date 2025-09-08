//
//  CommentReactor.swift
//  Bragit
//
//  Created by luca on 9/4/25.
//

import Dependencies
import Foundation
import ReactorKit
import RxFlow
import RxRelay
import RxSwift
import Supabase

final class CommentReactor: Reactor, Stepper {
  let initialState: State
  private let postId: UUID
  @Dependency(\.supabase) var supabase
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
    let commenterId: String?  // null/빈 값 허용
    let user: CommentUser?    // 조인 결과가 없을 수 있음
    let reports: Int?         // 신고 수

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
      print("CommentReactor refresh for postId: \(postId.uuidString)")
      let start = Observable.just(Mutation.setLoading(true))
      let setUser = Observable.just(Mutation.setCurrentUserId(storedUserId))
      let request = rxFetchComments(postId: postId)
        .do { rows in
          let formatter = DateFormatter()
          formatter.locale = Locale(identifier: "ko_KR")
          formatter.timeZone = .current
          formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
          rows.forEach { row in
            let dateString = formatter.string(from: row.date)
            let nick = row.user?.nickname?.isEmpty == false ? row.user!.nickname! : "탈퇴한 회원"
            print("nick: \(nick), content: \(row.content), date: \(dateString), reports: \(row.reports ?? 0)")
          }
        }
        .map { Mutation.setComments($0) as Mutation }
        .catch { error in
          let msg = (error as NSError).localizedDescription
          return .just(.setError(msg))
        }
      let end = Observable.just(Mutation.setLoading(false))
      return .concat([start, setUser, request, end])

    case .didTapBack:
      steps.accept(AppStep.pop)
      return .empty()

    case .sendComment(let content):
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

    case .didTapKebab(_):
      return .empty()

    case .deleteComment(let indexPath):
      // 화면과 동일한 정렬(최신순)로 대상 찾기
      let sorted = currentState.comments.sorted { $0.date > $1.date }
      guard indexPath.row >= 0, indexPath.row < sorted.count else {
        return .just(.setError("[Delete Comment] 인덱스 에러"))
      }
      let target = sorted[indexPath.row]

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

    case .reportComment(let indexPath):
      // 화면과 동일한 정렬(최신순)로 대상 찾기
      let sorted = currentState.comments.sorted { $0.date > $1.date }
      guard indexPath.row >= 0, indexPath.row < sorted.count else {
        return .just(.setError("[Report Comment] 인덱스 에러"))
      }
      let target = sorted[indexPath.row]

      // 신고 버튼이 눌렸을 때 대상 정보 로그 출력
      print("""
      [Report Tap]
      - id: \(target.id.uuidString)
      - post_id: \(target.postId.uuidString)
      - commenter_id: \(target.commenterId ?? "nil")
      - content: \(target.content)
      - reports(before): \(target.reports ?? 0)
      """)

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
          // 현재 유저 ID 가져오기
          guard let userId = self.storedUserId, userId.isEmpty == false else {
            throw NSError(
              domain: "CommentReactor",
              code: -1,
              userInfo: [NSLocalizedDescriptionKey: "로그인 필요"]
            )
          }

          let newCommentId = UUID()
          let currentDate = Date()

          // 댓글 전송
          let newComment = Comment(
            id: newCommentId,
            postId: self.postId,
            commenterId: userId,
            content: content,
            date: currentDate
          )

          print("[Comment] Sending...")
          try await self.supabase
            .from("Comment")
            .insert(newComment)
            .execute()
          print("[Comment] Success!")

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
          print("[Comment] 삭제될 댓글 Id: \(commentId.uuidString)")
          try await self.supabase
            .from("Comment")
            .delete()
            .eq("id", value: commentId)
            .execute()
          print("[Comment] 삭제 성공")
          observer.onNext(())
          observer.onCompleted()
        } catch {
          observer.onError(error)
        }
      }
      return Disposables.create { task.cancel() }
    }
  }

  // 신고: id로 reports(int4) +1
  // 업데이트가 실제 반영됐는지 다시 SELECT로 최종 검증하고, 모든 단계에서 상세 로그를 남김
  private func rxReportComment(commentId: UUID) -> Observable<Void> {
    struct Row: Codable { let reports: Int? }

    return .create { [weak self] observer in
      guard let self else {
        observer.onCompleted()
        return Disposables.create()
      }

      let task = Task {
        do {
          print("[Report] target id:", commentId.uuidString)

          // 1) 현재 값 읽기
          let before: Row = try await self.supabase
            .from("Comment")
            .select("reports")
            .eq("id", value: commentId)
            .single()
            .execute()
            .value
          let beforeCount = before.reports ?? 0
          print("[Report] before reports:", beforeCount)

          // 2) +1 업데이트 (returning 없이도 수행)
          try await self.supabase
            .from("Comment")
            .update(["reports": beforeCount + 1])
            .eq("id", value: commentId)
            .execute()
          print("[Report] update issued to:", beforeCount + 1)

          // 3) 다시 읽어서 실제 반영 확인
          let after: Row = try await self.supabase
            .from("Comment")
            .select("reports")
            .eq("id", value: commentId)
            .single()
            .execute()
            .value
          let afterCount = after.reports ?? 0
          print("[Report] after reports:", afterCount)

          guard afterCount == beforeCount + 1 else {
            throw NSError(
              domain: "CommentReactor",
              code: -3,
              userInfo: [NSLocalizedDescriptionKey: "신고 반영 실패(값 불일치)"]
            )
          }

          observer.onNext(())
          observer.onCompleted()
        } catch {
          print("[Report] error:", error.localizedDescription)
          observer.onError(error)
        }
      }
      return Disposables.create { task.cancel() }
    }
  }
}


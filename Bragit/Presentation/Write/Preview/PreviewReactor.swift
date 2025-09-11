//
//  PreviewReactor.swift
//  Bragit
//
//  Created by 이태윤 on 8/27/25.
//
import UIKit

import Dependencies
import ReactorKit
import RxSwift
import RxFlow
import RxRelay

class PreviewReactor: Reactor, Stepper {
  var initialState: State
  @Dependency(\.postManager) var postManager
  @Dependency(\.tagManager) var tagManager
  @Dependency(\.userManager) var userManager
  @Dependency(\.imageManager) var imageManager

  let draft: PostDraft
  let steps = PublishRelay<Step>()
  private let disposeBag = DisposeBag()

  // 사용자 액션 정의 (사용자의 의도)
  enum Action {
    case tapDismiss
    case tapPop
    case tapAddTag
    case addTag(String)
    case tapRemoveTag(String)
    case appendThumbnail(UIImage)
    case tapThumbnail(UIImage)
    case tapDone
  }

  // 상태변경 이벤트 정의 (상태를 어떻게 바꿀 것인가)
  enum Mutation {
    case appendTag(String)
    case removeTag(String)
    case appendThumbnail(UIImage)
    case setRepresentative(UIImage?)
    case setUploadResult(thumbnail: URL?, attachments: [URL]) // 업로드 결과 URL들
    case setError(Error)
    case setLoading(Bool)
    case setUploaded(Post)
  }

  // View의 상태 정의 (현재 View의 상태값)
  struct State {
    var title: String
    var content: NSAttributedString
    var thumbnails: [UIImage]
    var representativeImage: UIImage?
    var description: String
    var tags: [String] = []
    var isLoading: Bool = false
    var uploadedThumbnailURL: URL?
    var uploadedAttachmentURLs: [URL] = []

    @Pulse var presentTagModal = false
  }

  init(draft: PostDraft) {
    self.draft = draft
    let images = PreviewReactor.extractImages(from: draft.content)
    let decription = PreviewReactor.extractDecription(from: draft.content, limit: 80)
    self.initialState = State(title: draft.title, content: draft.content, thumbnails: images, description: decription)
  }

  // Action이 들어왔을 때 어떤 Mutation으로 바뀔지 정의
  // 사용자 입력 → 상태 변화 신호로 변환
  // swiftlint:disable cyclomatic_complexity
  func mutate(action: Action) -> Observable<Mutation> {
    switch action {
    case .tapDismiss:
      steps.accept(AppStep.dismiss)
      return .empty()

    case .tapPop:
      steps.accept(AppStep.pop)
      return .empty()

    case .tapAddTag:
      steps.accept(AppStep.writeTagSearch)
      return .empty()

    case .addTag(let tag):
      return .just(.appendTag(tag))

    case .tapRemoveTag(let tag):
      return .just(.removeTag(tag))

    case .appendThumbnail(let image):
      return .just(.appendThumbnail(image))

    case .tapThumbnail(let image):
      let nextRep: UIImage?
      if let current = currentState.representativeImage, current === image {
        nextRep = nil
      } else {
        nextRep = image
      }
      return .just(.setRepresentative(nextRep))

    case .tapDone:
      let author = self.authorId()
      let postId = UUID().uuidString
      print("유저 ID: \(author)")
      print("게시글 ID: \(postId)")

      let representativeImageData = currentState.representativeImage?.compress(for: .thumbnail)
      let contentImages = PreviewReactor.extractImages(from: currentState.content)
      let attachmentDataList = contentImages.compactMap { $0.compress(for: .content) }

      print("대표 이미지: \(representativeImageData != nil)")
      print("본문 이미지 개수: \(attachmentDataList.count)")

      // 업로드
      let thumbnailUploadStream: Observable<URL?> = {
        guard let data = representativeImageData else { return .just(nil) }
        let fileName = "thumbnail-\(Int(Date().timeIntervalSince1970)).jpg"
        return self.postManager.rxUploadImage(
          data: data,
          fileName: fileName,
          folder: StoragePath.thumbnail(authorId: author)
        )
        .map { $0 as URL? }
      }()

      let attachmentsUploadStream: Observable<[URL]> = {
        guard !attachmentDataList.isEmpty else { return .just([]) }
        return self.postManager.rxUploadImages(
          datas: attachmentDataList,
          folder: StoragePath.contents(authorId: author, postId: postId)
        )
      }()

      return Observable.concat([
        .just(.setLoading(true)),
        // 게시글 업로드
        Observable.zip(thumbnailUploadStream, attachmentsUploadStream)
          .flatMap { thumbnailURL, attachmentURLs -> Observable<Mutation> in
            print("썸네일 URL: \(thumbnailURL?.absoluteString ?? "없음")")
            print("본문 이미지 URL: \(attachmentURLs.map { $0.absoluteString })")

            let setUploadMutation = Mutation.setUploadResult(thumbnail: thumbnailURL, attachments: attachmentURLs)
            let contentForSave = self.replacingAttachmentsWithURLs(in: self.currentState.content, urls: attachmentURLs)

            let archivedContentData: Data
            do {
              archivedContentData = try self.archiveAttributedString(contentForSave)
            } catch {
              print("아카이빙 실패: \(error.localizedDescription)")
              return .just(.setError(error))
            }
            return self.tagManager.rxUpsertTags(names: self.currentState.tags)
              .flatMap { ensuredTags -> Observable<Post> in
                print("태그: \(ensuredTags.map { $0.tag })")
                return self.postManager.rxCreatePost(
                  postId: postId,
                  authorId: author,
                  title: self.currentState.title,
                  description: self.currentState.description,
                  thumbnailURL: thumbnailURL,
                  archivedContent: archivedContentData
                )
                .flatMap { savedPost -> Observable<Post> in
                  print("게시글 생성 완료: \(savedPost.id)")
                  return self.postManager.rxAttachTags(postId: savedPost.id.uuidString, tagIds: ensuredTags.map(\.id))
                    .flatMap { [weak self] _ -> Observable<Void> in
                      guard let self = self else { return .empty() }
                      print("태그 첨부 완료.")
                      return self.userManager.rxUpdateLastUploaded(userId: author, at: Date())
                    }
                    .map { _ in savedPost }
                }
              }
              .map { savedPost in
                print("최종 데이터 생성. 완료")
                return Mutation.setUploaded(savedPost)
              }
            // swiftlint:disable:next trailing_closure
              .do(onNext: { [weak self] _ in
                self?.steps.accept(AppStep.dismiss)
              })
              .startWith(setUploadMutation)
          }
          .catch { error -> Observable<Mutation> in
            print("tapDone 스트림 에러: \(error.localizedDescription)")
            return .just(.setError(error))
          }
      ])
    }
  }
  // swiftlint:enable cyclomatic_complexity

  // Mutation이 발생했을 때 상태(State)를 실제로 바꿈
  // 상태 변화 신호 → 실제 상태 반영
  func reduce(state: State, mutation: Mutation) -> State {
    var newState = state
    switch mutation {
    case .appendTag(let tag):
      if !state.tags.contains(tag) {
        newState.tags.append(tag)
      }

    case .removeTag(let tag):
      newState.tags.removeAll { $0 == tag }

    case .appendThumbnail(let thumbnil):
      newState.thumbnails.insert(thumbnil, at: 0)

    case .setRepresentative(let image):
      newState.representativeImage = image

    case let .setUploadResult(thumbnail, attachments):
      newState.uploadedThumbnailURL = thumbnail
      newState.uploadedAttachmentURLs = attachments

    case .setLoading(let flag):
      newState.isLoading = flag

    case .setUploaded(_):
      newState.isLoading = false
    case .setError(let error):
      newState.isLoading = false
      print("PreviewReactor Error:", error.localizedDescription)
    }

    return newState
  }

  func transform(state: Observable<State>) -> Observable<State> {
    return state.observe(on: MainScheduler.instance)
  }

  // NSAttributedString에서 이미지 뽑아 내기
  static func extractImages(from attributedString: NSAttributedString) -> [UIImage] {
    var images: [UIImage] = []

    attributedString.enumerateAttribute(
      .attachment, in: NSRange(location: 0, length: attributedString.length)
    ) { value, _, _ in
      if let attachment = value as? NSTextAttachment, let image = attachment.image {
        images.append(image)
      }
    }
    return images
  }

  // 요약
  static func extractDecription(from attributedString: NSAttributedString, limit: Int = 80) -> String {
    let plainText = attributedString.string
    let cleanedText = plainText
      .replacingOccurrences(of: "^\n+", with: "", options: .regularExpression) // 맨 앞 줄바꿈 제거
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let preview = String(cleanedText.prefix(limit))
    return preview
  }

  // 본문 내 이미지들을 URL 텍스트로 치환
  func replacingAttachmentsWithURLs(
    in original: NSAttributedString,
    urls: [URL]
  ) -> NSAttributedString {
    var attachmentRanges: [NSRange] = []
    original.enumerateAttribute(
      .attachment,
      in: NSRange(location: 0, length: original.length)) { value, range, _ in
        if value is NSTextAttachment {
          attachmentRanges.append(range)
        }
      }

    let replaceCount = min(attachmentRanges.count, urls.count)
    if replaceCount == 0 { return original }

    let mutable = NSMutableAttributedString(attributedString: original)

    // 뒤에서부터 치환 하여 range 변형 방지
    for i in stride(from: replaceCount - 1, through: 0, by: -1) {
      let replaceRange = attachmentRanges[i]
      let urlString = urls[i].absoluteString
      let replacement = NSMutableAttributedString(string: urlString)

      if let url = URL(string: urlString) {
        replacement.addAttribute(.link, value: url, range: NSRange(location: 0, length: replacement.length))
      }
      mutable.replaceCharacters(in: replaceRange, with: replacement)
    }
    return mutable
  }

  // 아카이빙
  func archiveAttributedString(_ attributed: NSAttributedString) throws -> Data {
    let data = try NSKeyedArchiver.archivedData(withRootObject: attributed, requiringSecureCoding: true)
    return data
  }
}

extension PreviewReactor {
  private func authorId() -> String {
    if let id = UserDefaults.standard.string(forKey: LocalStorageCase.nowUser.rawValue) {
      return id
    }
    // 누락 확인용
    assertionFailure("UserDefaults.userId 가 없습니다.")
    return "unknown"
  }
}

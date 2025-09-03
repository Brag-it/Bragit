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

      #if DEBUG
      print("authorId:", author)
      print("postId:", postId)
      #endif

      let thumbData = currentState.representativeImage?.compress(for: .thumbnail)
      let contentImages = PreviewReactor.extractImages(from: currentState.content)
      let attachmentDatas = contentImages.compactMap { $0.compress(for: .content) }

      #if DEBUG
      let origThumbInfo: String = {
        if let img = self.currentState.representativeImage {
          return "size=\(img.size), scale=\(img.scale)"
        } else {
          return "nil"
        }
      }()
      print("대표이미지 원본:", origThumbInfo)
      print("본문 내 원본 이미지 개수:", contentImages.count)
      print("압축 썸네일 바이트:", thumbData?.count ?? 0)
      print("압축 첨부 바이트 총합:", attachmentDatas.reduce(0, { $0 + $1.count }))
      #endif

      // 썸네일 업로드
      let thumbUploadStream: Observable<URL?> = {
        if let data = thumbData {
          return self.postManager.rxUploadImage(
            data: data,
            fileName: "thumbnail-\(Int(Date().timeIntervalSince1970)).jpg",
            folder: StoragePath.thumbnail(authorId: author)
          )
          .map { $0 as URL? }
        } else {
          return .just(nil)
        }
      }()

      // 첨부 업로드
      let attachmentsUploadStream: Observable<[URL]> = {
        if attachmentDatas.isEmpty {
          return .just([])
        } else {
          return self.postManager.rxUploadImages(
            datas: attachmentDatas,
            folder: StoragePath.contents(authorId: author, postId: postId)
          )
        }
      }()

      return Observable.concat([
        .just(.setLoading(true)),

        // 이미지 업로드
        Observable.zip(thumbUploadStream, attachmentsUploadStream)
          .flatMap { thumbURL, attachmentURLs -> Observable<Mutation> in
            #if DEBUG
            print("업로드 완료")
            print("썸네일 URL:", thumbURL?.absoluteString ?? "nil")
            print("첨부 URL 개수:", attachmentURLs.count)
            if !attachmentURLs.isEmpty {
              print("첨부 URL 리스트:", attachmentURLs.map { $0.absoluteString })
            }
            #endif
            // 업로드 결과를 먼저 State에 반영
            let setUpload = Observable.just(
              Mutation.setUploadResult(thumbnail: thumbURL, attachments: attachmentURLs)
            )

            // 본문 치환 + 아카이빙
            let contentForSave = self.replacingAttachmentsWithURLs(
              in: self.currentState.content,
              urls: attachmentURLs
            )
            #if DEBUG
            print("치환 후 텍스트: \(contentForSave.string)")
            #endif

            let archivedData: Data
            do {
              archivedData = try self.archiveAttributedString(contentForSave)
              #if DEBUG
              print("아카이빙 완료: 바이트 =", archivedData.count)
              #endif
            } catch {
              // 아카이빙 실패 시 에러 상태 반영 후 종료
              return Observable.concat([setUpload, .just(.setError(error))])
            }
            // 태그 업서트 → 포스트 저장 → 포스트-태그 매핑
            let upsertAndSave = self.tagManager.rxUpsertTags(names: self.currentState.tags)
              .flatMap { ensuredTags -> Observable<Mutation> in
                #if DEBUG
                print("태그 업서트 완료: 보장된 태그 IDs =", ensuredTags.map { $0.id })
                #endif
                // Author는 객체로 구성
                let authorObj = Author(id: author, nickname: nil, profile: nil)
                let newPost = Post(
                  id: UUID(uuidString: postId) ?? UUID(),
                  title: self.currentState.title,
                  thumbnailImage: thumbURL?.absoluteString,
                  author: authorObj,
                  date: Date(),
                  content: contentForSave.string,
                  like: 0,
                  reports: 0,
                  commentCount: 0,
                  description: self.currentState.description
                )

                return self.postManager.rxCreatePost(
                  postId: postId,
                  authorId: author,
                  title: newPost.title,
                  description: newPost.description,
                  thumbnailURL: thumbURL,
                  archivedContent: archivedData
                )
                .flatMap { savedPost in
                  #if DEBUG
                  print("Post 저장 완료: id =", savedPost.id)
                  print("post_tags 매핑 시작: tagIds =", ensuredTags.map { $0.id })
                  #endif
                  return self.postManager.rxAttachTags(postId: postId, tagIds: ensuredTags.map(\.id))
                    .map {
                      #if DEBUG
                      print("post_tags 매핑 완료")
                      #endif
                      return Mutation.setUploaded(savedPost)
                    }
                }
              }
            // 업로드 결과

            return Observable.concat([setUpload, upsertAndSave])
          },
        .just(.setLoading(false))
      ])
    }
  }
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
      break
    case .setError(let error):
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
      print("ID: \(id)")
      return id
    }
    // 누락 확인용
    assertionFailure("UserDefaults.userId 가 없습니다.")
    return "unknown"
  }
}

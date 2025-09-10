//
//  PostDraft.swift
//  Bragit
//
//  Created by 이태윤 on 8/27/25.
//
// 업로드 전까지 고유 ID 보관
import UIKit

import RxSwift

final class EditorImageAttachment: NSTextAttachment {
  let localId = UUID().uuidString // 업로드/치환 시 매칭용
}

struct PostDraft {
  let title: String                   // 제목
  let content: NSAttributedString     // 내용
}

struct PostUpdate {
  let id: UUID
  let title: String
  let content: NSAttributedString
}

// 업로더 프로토콜 (DI)
protocol ImageUploader {
  func upload(jpeg data: Data, filename: String) -> Single<URL>
}

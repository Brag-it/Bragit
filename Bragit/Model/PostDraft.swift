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

// 임시저장
struct PostTemporary: Codable {
  let title: String
  let content: NSAttributedString

  init(title: String, content: NSAttributedString) {
    self.title = title
    self.content = content
  }

  enum CodingKeys: String, CodingKey {
    case title, content
  }

  // 임시저장할 때
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(title, forKey: .title)

    let data = try NSKeyedArchiver.archivedData(withRootObject: content, requiringSecureCoding: false)
    try container.encode(data, forKey: .content)
  }

  // 임시저장 된 게시글 불러올 때
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    title = try container.decode(String.self, forKey: .title)

    let data = try container.decode(Data.self, forKey: .content)
    guard let attributed = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data) else {
      throw DecodingError.dataCorruptedError(forKey: .content, in: container, debugDescription: "Failed to decode NSAttributedString")
    }
    content = attributed
  }
}

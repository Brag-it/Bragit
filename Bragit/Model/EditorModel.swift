//
//  EditorModel.swift
//  Bragit
//
//  Created by 이태윤 on 8/28/25.
//
// 업로드 전까지 고유 ID 보관
import UIKit

import RxSwift

final class EditorImageAttachment: NSTextAttachment {
  let localId = UUID().uuidString // 업로드/치환 시 매칭용
}

struct EditorDraft {
  let title: String
  let bodyData: Data
  let updatedAt: Date
}

// 3) 업로더 프로토콜 (DI)
protocol ImageUploader {
  func upload(jpeg data: Data, filename: String) -> Single<URL>
}

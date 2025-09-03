//
//  UIImage++.swift
//  Bragit
//
//  Created by 이태윤 on 9/2/25.
//
import UIKit

extension UIImage {
  // Post 저장용으로 리사이즈 & 압축 → Data 반환
  func compress(for type: PostImageType) -> Data? {
    let (maxDimension, quality) = type.config

    let originalSize = size
    let longestSide = max(originalSize.width, originalSize.height)

    // 이미 충분히 작으면 리사이즈 생략
    let scale = longestSide > maxDimension ? (maxDimension / longestSide) : 1.0
    let targetSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)

    // CoreGraphics 기반 리사이즈
    UIGraphicsBeginImageContextWithOptions(targetSize, true, 1.0)
    defer { UIGraphicsEndImageContext() }
    draw(in: CGRect(origin: .zero, size: targetSize))
    let resized = UIGraphicsGetImageFromCurrentImageContext()

    // JPEG 압축
    return resized?.jpegData(compressionQuality: quality)
  }
}

//
//  UIImage++.swift
//  Bragit
//
//  Created by 이태윤 on 9/2/25.
//
import UIKit

extension UIImage {
  // 특정 크기로 이미지 리사이즈 (비율 유지)
  func resized(in boundsSize: CGSize) -> UIImage? {
     let ratio = min(boundsSize.width / size.width, boundsSize.height / size.height)
     return resized(to: CGSize(width: size.width * ratio, height: size.height * ratio))
  }

  // 특정 크기로 이미지 리사이즈 (강제)
  func resized(to size: CGSize) -> UIImage {
    return UIGraphicsImageRenderer(size: size).image { _ in
      draw(in: CGRect(origin: .zero, size: size))
    }
  }
}

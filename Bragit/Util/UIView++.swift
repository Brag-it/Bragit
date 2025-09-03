//
//  UIView++.swift
//  Bragit
//
//  Created by 이태윤 on 9/4/25.
//
import UIKit

extension UIView {
  // 좌우로 살짝 흔들리는 경고 애니메이션
  func shake(times: Int = 2, offset: CGFloat = 6, durationPerHalfCycle: TimeInterval = 0.07) {
    let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
    animation.timingFunction = CAMediaTimingFunction(name: .linear)
    animation.duration = durationPerHalfCycle * Double(times) * 2
    var values: [CGFloat] = []
    for _ in 0..<times { values += [-offset, offset] }
    values.append(0)
    animation.values = values
    layer.add(animation, forKey: "shake")
  }
}


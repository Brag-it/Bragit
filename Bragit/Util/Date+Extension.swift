
import Foundation

extension Date {
  // Date to AgoText
  func timeAgoDisplay() -> String {
    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.second, .minute, .hour, .day, .month], from: self, to: now)

    if let month = components.month, month > 0 {
      return "\(month)달 전"
    } else if let day = components.day, day > 0 {
      return "\(day)일 전"
    } else if let hour = components.hour, hour > 0 {
      return "\(hour)시간 전"
    } else if let minute = components.minute, minute > 0 {
      return "\(minute)분 전"
    } else if let second = components.second, second > 0 {
      return "\(second)초 전"
    } else {
      return "방금 전"
    }
  }
}

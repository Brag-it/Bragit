import UIKit
import RxSwift
import RxCocoa

final class SignupViewModel {
  private let pendingEmailKey = "pendingSignupEmail"
  private var pendingEmail: String? {
    get { UserDefaults.standard.string(forKey: pendingEmailKey) }
    set { UserDefaults.standard.set(newValue, forKey: pendingEmailKey) }
  }

  init() {
    // Initialization code here
  }

  /// The email captured in step 1, if any.
  func currentEmail() -> String? { pendingEmail }

  // Other properties and methods...
}

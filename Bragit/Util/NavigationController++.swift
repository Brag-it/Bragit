//
//  NavigationController++.swift
//  Bragit
//
//  Created by 이태윤 on 9/9/25.
//
import UIKit

class NavigationController: UINavigationController {
  private lazy var popGestureDelegate = InteractivePopGestureRecognizerDelegate(navigationController: self)

  override func viewDidLoad() {
      super.viewDidLoad()
      interactivePopGestureRecognizer?.delegate = popGestureDelegate
    }
}

extension NavigationController {
  private class InteractivePopGestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate {
    weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController) {
      self.navigationController = navigationController
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
      return navigationController.map { $0.viewControllers.count > 1 } ?? false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
      return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
      return true
    }
  }
}

//
//  FavoriteFlow.swift
//  Bragit
//
//  Created by 이태윤 on 8/26/25.
//
import UIKit

import RxFlow

final class FavoriteFlow: Flow {
  var root: Presentable { nav }
  private let nav = UINavigationController()

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? AppStep else { return .none }
    switch step {
    case .favorite:
      let favoriteVC = FavoriteViewController()
      nav.setViewControllers([favoriteVC], animated: false)
      return .none
    default:
      return .none
    }
  }
}

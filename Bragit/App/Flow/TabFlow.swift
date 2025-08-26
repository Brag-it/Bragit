//
//  TabFlow.swift
//  Bragit
//
//  Created by 이태윤 on 8/26/25.
//
import UIKit

import RxFlow

// 탭바 네비게이션 전담
final class TabFlow: Flow {

  var root: Presentable {
    return self.rootViewController
  }

  private let rootViewController = UITabBarController()
  private let homeFlow = HomeFlow()
  private let favoriteFlow = FavoriteFlow()
  private let writeFeedFlow = WriteFeedFlow()
  private let myPageFlow = MyPageFlow()

  init() {}

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? AppStep else { return .none }

    switch step {
    case .home:
      return coordinateToTabBar()
    default:
      return .none
    }
  }

  private func coordinateToTabBar() -> FlowContributors {
    Flows.use(homeFlow, favoriteFlow, writeFeedFlow, myPageFlow, when: .ready) { [unowned self]
      (homeRoot, favoriteRoot, writeRoot, myRoot) in

      let homeTabBarItem = UITabBarItem(title: "홈", image: .home, tag: 0)
      let favoriteTabBarItem = UITabBarItem(title: "관심", image: .favorite, tag: 1)
      let writeTabBarItem = UITabBarItem(title: "글쓰기", image: .write, tag: 2)
      let myPageTabBarItem = UITabBarItem(title: "마이", image: .mypage, tag: 3)

      homeRoot.tabBarItem = homeTabBarItem
      favoriteRoot.tabBarItem = favoriteTabBarItem
      writeRoot.tabBarItem = writeTabBarItem
      myRoot.tabBarItem = myPageTabBarItem

      self.rootViewController.setViewControllers([homeRoot, favoriteRoot, writeRoot, myRoot], animated: false)
    }

    return .multiple(flowContributors: [
      .contribute(withNextPresentable: homeFlow, withNextStepper: OneStepper(withSingleStep: AppStep.home)),
      .contribute(withNextPresentable: favoriteFlow, withNextStepper: OneStepper(withSingleStep: AppStep.favorite)),
      .contribute(withNextPresentable: writeFeedFlow, withNextStepper: OneStepper(withSingleStep: AppStep.writeFeed)),
      .contribute(withNextPresentable: myPageFlow, withNextStepper: OneStepper(withSingleStep: AppStep.myPage))
    ])
  }
}

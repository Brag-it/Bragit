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
  var root: Presentable { tabBar }
  private let tabBar = UITabBarController()

  private let homeFlow = HomeFlow()
  private let favoriteFlow = FavoriteFlow()
  private let writeFeedFlow = WriteFeedFlow()
  private let myPageFlow = MyPageFlow()
  private var isSetup = false

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? AppStep else { return .none }
    setupIfNeeded()

    switch step {
    case .home:
      tabBar.selectedIndex = 0
      return .one(flowContributor: .forwardToCurrentFlow(withStep: step))
    case .favorite:
      tabBar.selectedIndex = 1
      return .one(flowContributor: .forwardToCurrentFlow(withStep: step))
    case .writeFeed:
      tabBar.selectedIndex = 2
      return .one(flowContributor: .forwardToCurrentFlow(withStep: step))
    case .myPage:
      tabBar.selectedIndex = 3
      return .one(flowContributor: .forwardToCurrentFlow(withStep: step))
    default:
      return .none
    }
  }

  private func setupIfNeeded() {
    guard !isSetup else { return }
    isSetup = true

    // 모든 탭 Flow를 한 번만 구성
    Flows.use(homeFlow, favoriteFlow, writeFeedFlow, myPageFlow, when: .ready) { [weak self]
      (homeRoot: UINavigationController,
      favoriteRoot: UINavigationController,
      writeRoot: UINavigationController,
      myRoot: UINavigationController) in

      // 탭 아이템 설정
      homeRoot.tabBarItem = UITabBarItem(title: "홈", image: .home, tag: 0)
      favoriteRoot.tabBarItem = UITabBarItem(title: "관심", image: .favorite, tag: 1)
      writeRoot.tabBarItem = UITabBarItem(title: "글쓰기", image: .write, tag: 2)
      myRoot.tabBarItem = UITabBarItem(title: "마이", image: .mypage, tag: 3)

      // 탭바에 루트들 등록
      self?.tabBar.setViewControllers([homeRoot, favoriteRoot, writeRoot, myRoot], animated: false)
    }
  }
}

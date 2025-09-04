//
//  TabFlow.swift
//  Bragit
//
//  Created by 이태윤 on 8/26/25.
//
import UIKit

import RxFlow
import RxRelay

// 탭바 네비게이션 전담
final class TabFlow: NSObject, Flow, Stepper {

  var root: Presentable {
    return self.rootViewController
  }

  private let rootViewController = UITabBarController()
  private let homeFlow = HomeFlow()
  private let favoriteFlow = FavoriteFlow()
  private let writeFeedFlow = WriteFeedFlow()
  private let myPageFlow = MyPageFlow()
  let steps = PublishRelay<Step>()

  override init() {
    super.init()
    rootViewController.delegate = self
  }

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? AppStep else { return .none }
    switch step {
    case .home:
      return coordinateToTabBar()
    case .writeFeed:
      return presentWriteFlow()
    case .feedDetail(let post):
      return showDetailPost(post: post)
    case .comment(let id):
      return showComment(id: id)
    default:
      return .none
    }
  }

  private func coordinateToTabBar() -> FlowContributors {
    Flows.use(homeFlow, favoriteFlow, writeFeedFlow, myPageFlow, when: .ready) { [unowned self]
      (homeRoot, favoriteRoot, writeRoot, myRoot) in

      let homeTabBarItem = UITabBarItem(title: "홈", image: .home, selectedImage: .homeFilled)
      homeTabBarItem.tag = 0
      let favoriteTabBarItem = UITabBarItem(title: "관심", image: .favorite, selectedImage: .favoriteFilled)
      favoriteTabBarItem.tag = 1
      let writeTabBarItem = UITabBarItem(title: "글쓰기", image: .write, selectedImage: .writeFilled)
      writeTabBarItem.tag = 2
      let myPageTabBarItem = UITabBarItem(title: "마이", image: .mypage, selectedImage: .mypageFilled)
      myPageTabBarItem.tag = 3

      homeRoot.tabBarItem = homeTabBarItem
      favoriteRoot.tabBarItem = favoriteTabBarItem
      writeRoot.tabBarItem = writeTabBarItem
      myRoot.tabBarItem = myPageTabBarItem

      self.rootViewController.setViewControllers([homeRoot, favoriteRoot, writeRoot, myRoot], animated: true)
      self.rootViewController.selectedIndex = 0

      let tabBar = self.rootViewController.tabBar
      tabBar.tintColor = .grayScaleBack

      let appearance = UITabBarAppearance()
      appearance.configureWithOpaqueBackground()
      appearance.backgroundColor = .systemBackground
      appearance.shadowColor = .lightGray

      let fontAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.pretendard(size: 12, weight: .medium)
      ]
      appearance.stackedLayoutAppearance.normal.titleTextAttributes = fontAttributes
      appearance.stackedLayoutAppearance.selected.titleTextAttributes = fontAttributes

      tabBar.standardAppearance = appearance
      tabBar.scrollEdgeAppearance = appearance
    }

    return .multiple(flowContributors: [
      .contribute(withNextPresentable: homeFlow, withNextStepper: OneStepper(withSingleStep: AppStep.home)),
      .contribute(withNextPresentable: favoriteFlow, withNextStepper: OneStepper(withSingleStep: AppStep.favorite)),
      .contribute(withNextPresentable: writeFeedFlow, withNextStepper: OneStepper(withSingleStep: AppStep.writeFeed)),
      .contribute(withNextPresentable: myPageFlow, withNextStepper: OneStepper(withSingleStep: AppStep.myPage))
    ])
  }

  private func presentWriteFlow() -> FlowContributors {
    let flow = WriteFeedFlow() // 모달로 띄울 전용 플로우
    Flows.use(flow, when: .ready) { [weak self] root in
      root.modalPresentationStyle = .fullScreen
      root.modalTransitionStyle = .crossDissolve
      self?.rootViewController.present(root, animated: true)
    }
    return .one(flowContributor: .contribute(
      withNextPresentable: flow,
      withNextStepper: OneStepper(withSingleStep: AppStep.writeFeed)
    ))
  }

  func showDetailPost(post: Post) -> FlowContributors {
    guard let navigation = rootViewController.selectedViewController as? UINavigationController else { return .none }
    let reactor = DetailPostReactor(post: post)
    let detailPostVC = DetailPostViewController(reactor: reactor)

    detailPostVC.hidesBottomBarWhenPushed = true
    navigation.pushViewController(detailPostVC, animated: true)

    return .one(flowContributor: .contribute(
      withNextPresentable: detailPostVC,
      withNextStepper: reactor
    ))
  }

  func showComment(id: UUID)  -> FlowContributors {
    guard let navigation = rootViewController.selectedViewController as? UINavigationController else { return .none }
    let reactor = CommentReactor(id: id)
    let commentVC = CommentViewController(reactor: reactor)

    commentVC.hidesBottomBarWhenPushed = true
    navigation.pushViewController(commentVC, animated: true)

    return .one(flowContributor: .contribute(
      withNextPresentable: commentVC,
      withNextStepper: reactor
    ))
  }
}

extension TabFlow: UITabBarControllerDelegate {
  func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
    guard let index = tabBarController.viewControllers?.firstIndex(where: { $0 == viewController }), index == 2 else {
      return true
    }
    //    tabBarController.selectedViewController?.present(WriteViewController(reactor: WriteReactor()), animated: true)
    steps.accept(AppStep.writeFeed)
    return false
  }
}

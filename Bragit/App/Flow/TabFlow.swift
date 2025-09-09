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
  // swiftlint:disable cyclomatic_complexity
  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? AppStep else { return .none }
    switch step {
    case .dismiss:
      return dismiss()
    case .pop:
      return pop()
    case .home:
      return coordinateToTabBar()
    case .writeFeed:
      return presentWriteFlow()
    case .feedDetail(let post):
      return showDetailPost(post: post)
    case .comment(let id):
      return showComment(id: id)
    case .tagInform(let tag):
      return showTagDetail(tag: tag)
    case .searchFeed:
      return showsearchView()
    case .userProfile(let user):
      return showUserProfile(user: user)
    default:
      return .one(flowContributor: .forwardToParentFlow(withStep: step))
    }
  }
  // swiftlint:enable cyclomatic_complexity
  func dismiss() -> FlowContributors {
    guard let navigation = rootViewController.selectedViewController as? UINavigationController else { return .none }
    navigation.dismiss(animated: true)
    return .none
  }

  func pop() -> FlowContributors {
    guard let navigation = rootViewController.selectedViewController as? UINavigationController else { return .none }
    navigation.popViewController(animated: true)
    return .none
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

  func showComment(id: UUID) -> FlowContributors {
    guard let navigation = rootViewController.selectedViewController as? UINavigationController else { return .none }
    let reactor = CommentReactor(postId: id)
    let commentVC = CommentViewController(reactor: reactor)

    commentVC.hidesBottomBarWhenPushed = true
    navigation.pushViewController(commentVC, animated: true)

    return .one(flowContributor: .contribute(
      withNextPresentable: commentVC,
      withNextStepper: reactor
    ))
  }

  func showTagDetail(tag: Tag) -> FlowContributors {
    guard let navigation = rootViewController.selectedViewController as? UINavigationController else { return .none }
    let reactor = TagDetailReactor(tag: tag)
    let tagDetailVC = TagDetailViewController(reactor: reactor)

    navigation.pushViewController(tagDetailVC, animated: true)

    return .one(flowContributor: .contribute(
      withNextPresentable: tagDetailVC,
      withNextStepper: reactor
    ))
  }

  func showsearchView() -> FlowContributors {
    let flow = SearchFlow() // 모달로 띄울 전용 플로우
    Flows.use(flow, when: .ready) { [weak self] root in
      root.modalPresentationStyle = .fullScreen
      root.modalTransitionStyle = .crossDissolve
      self?.rootViewController.present(root, animated: true)
    }
    return .one(flowContributor: .contribute(
      withNextPresentable: flow,
      withNextStepper: OneStepper(withSingleStep: AppStep.searchFeed)
    ))
  }

  func showUserProfile(user: User) -> FlowContributors {
    guard let navigation = rootViewController.selectedViewController as? UINavigationController else { return .none }
    let reactor = UserProfileReactor(user: user)
    let userProfileVC = UserProfileViewCotnroller(reactor: reactor)

    navigation.pushViewController(userProfileVC, animated: true)

    return .one(flowContributor: .contribute(
      withNextPresentable: userProfileVC,
      withNextStepper: reactor
    ))
  }
}

extension TabFlow: UITabBarControllerDelegate {
  func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
    guard let index = tabBarController.viewControllers?.firstIndex(of: viewController) else {
      return true
    }

    if index == 0 && tabBarController.selectedIndex == 0 {
      if let nav = viewController as? UINavigationController,
        let homeVC = nav.viewControllers.first as? HomeViewController {
        homeVC.scrollToTop()
      }
    }

    if index == 1 && tabBarController.selectedIndex == 1 {
      if let nav = viewController as? UINavigationController,
        let favoriteVC = nav.viewControllers.first as? FavoriteViewController {
        favoriteVC.scrollToTop()
      }
    }

    if index == 2 {
      steps.accept(AppStep.writeFeed)
      return false
    }

    return true
  }
}

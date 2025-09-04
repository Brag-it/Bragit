//
//  MyPageFlow.swift
//  Bragit
//
//  Created by 이태윤 on 8/26/25.
//
import UIKit

import RxFlow

final class MyPageFlow: Flow {
  var root: Presentable { nav }
  private let nav = UINavigationController()

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? AppStep else { return .none }
    switch step {
    case .myPage:
      return showMyPageRoot()
    case .setting:
      return showSetting()
    case .dismiss:
      nav.popViewController(animated: true)
      return .none
    case .followersList(let users):
      return showFollowerList(users: users)
    case .followingList(let users):
      return showFollowingList(users: users)
    case .favoriteList(let tags):
      return showFavoritTagsList(tags: tags)
    case .cancelAccount:
      return showCancelAccount()
    default:
      return .none
    }
  }

  private func showMyPageRoot() -> FlowContributors {
    let reactor = MyPageReactor()
    let mypageVC = MyPageViewController(reactor: reactor)
    nav.setViewControllers([mypageVC], animated: true)
    return .one(flowContributor: .contribute(
      withNextPresentable: mypageVC,
      withNextStepper: reactor
    ))
  }

  private func showSetting() -> FlowContributors {
    let reactor = SettingReactor()
    let settingVC = SettingViewController(reactor: reactor)
    nav.pushViewController(settingVC, animated: true)
    return .one(flowContributor: .contribute(
      withNextPresentable: settingVC,
      withNextStepper: reactor
    ))
  }

  private func showFollowerList(users: [User]) -> FlowContributors {
    let reactor = FollowerReactor()
    let followerVC = FollowerViewController(reactor: reactor, users: users)
    nav.pushViewController(followerVC, animated: true)
    return .one(flowContributor: .contribute(
      withNextPresentable: followerVC,
      withNextStepper: reactor
    ))
  }

  private func showFollowingList(users: [User]) -> FlowContributors {
    let reactor = FollowingReactor()
    let followingVC = FollowingViewController(reactor: reactor, users: users)
    nav.pushViewController(followingVC, animated: true)
    return .one(flowContributor: .contribute(
      withNextPresentable: followingVC,
      withNextStepper: reactor
    ))
  }

  private func showFavoritTagsList(tags: [Tag]) -> FlowContributors {
    let reactor = FavoriteTagsReactor()
    let favoriteTagsVC = FavoriteTagsViewController(reactor: reactor, tags: tags)
    nav.pushViewController(favoriteTagsVC, animated: true)
    return .one(flowContributor: .contribute(
      withNextPresentable: favoriteTagsVC,
      withNextStepper: reactor
    ))
  }

  private func showCancelAccount() -> FlowContributors {
    let reactor = CancelAccountReactor()
    let cancelAccountVC = CancelAccountViewController(reactor: reactor)
    nav.pushViewController(cancelAccountVC, animated: true)
    return .one(flowContributor: .contribute(
      withNextPresentable: cancelAccountVC,
      withNextStepper: reactor
    ))
  }
}

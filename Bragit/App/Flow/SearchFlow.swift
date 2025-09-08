//
//  SearchFlow.swift
//  Bragit
//
//  Created by 이태윤 on 9/9/25.
//
import UIKit
import RxFlow

final class SearchFlow: Flow {
  var root: Presentable { nav }
  private let nav = UINavigationController()

  init() {
    nav.setNavigationBarHidden(true, animated: false)
  }

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? AppStep else { return .none }
    switch step {
    case .searchFeed:
      return showSearchRoot()

    case .dismiss:
      nav.dismiss(animated: true)
      return .none

    case .pop:
      nav.popViewController(animated: true)
      return .none

    case .tagInform(let tag):
      return searchShowTagDetail(tag: tag)

    case .feedDetail(let post):
      return searchShowDetailPost(post: post)

    case .userProfile(let user):
      return searchShowUserProfile(user: user)

    default:
      return .none
    }
  }

  private func showSearchRoot() -> FlowContributors {
    let reactor = SearchReactor()
    let searchVC = SearchViewController(reactor: reactor)

    nav.setViewControllers([searchVC], animated: true)

    return .one(flowContributor: .contribute(
      withNextPresentable: searchVC,
      withNextStepper: reactor
    ))
  }

  func searchShowTagDetail(tag: Tag) -> FlowContributors {
    let reactor = TagDetailReactor(tag: tag)
    let tagDetailVC = TagDetailViewController(reactor: reactor)

    nav.pushViewController(tagDetailVC, animated: true)

    return .one(flowContributor: .contribute(
      withNextPresentable: tagDetailVC,
      withNextStepper: reactor
    ))
  }

  func searchShowDetailPost(post: Post) -> FlowContributors {
    let reactor = DetailPostReactor(post: post)
    let detailPostVC = DetailPostViewController(reactor: reactor)

    nav.pushViewController(detailPostVC, animated: true)

    return .one(flowContributor: .contribute(
      withNextPresentable: detailPostVC,
      withNextStepper: reactor
    ))
  }

  func searchShowUserProfile(user: User) -> FlowContributors {
    let reactor = UserProfileReactor(user: user)
    let userProfileVC = UserProfileViewCotnroller(reactor: reactor)

    nav.pushViewController(userProfileVC, animated: true)

    return .one(flowContributor: .contribute(
      withNextPresentable: userProfileVC,
      withNextStepper: reactor
    ))
  }
}

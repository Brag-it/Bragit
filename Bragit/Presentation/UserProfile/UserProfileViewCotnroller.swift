//
//  UserProfileViewCotnroller.swift
//  Bragit
//
//  Created by 이태윤 on 9/8/25.
//

import UIKit

import ReactorKit
import RxSwift
import RxCocoa

class UserProfileViewCotnroller: UIViewController, View {
  var disposeBag = DisposeBag()

  private let userProfileView = UserProfileView()

  private let menuView = MenuView(items: ["차단하기", "신고하기"], width: 120)

  init(reactor: UserProfileReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    view = userProfileView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.navigationBar.isHidden = true
  }

  func bind(reactor: UserProfileReactor) {
    // 데이터 세팅
    self.rx.viewDidLoad
      .flatMap {
        Observable.from([
          .setUserInform,
          .loadPosts
        ])
      }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 스테이트 바인딩
    reactor.state.bind { [userProfileView] in
      let profile = Profile(
        nickName: $0.nickName,
        profileImage: $0.profileImage,
        follwerCount: $0.followersCount,
        followingCount: $0.followingsCount,
        favoriteTagCount: 0,
        isFollowing: $0.isFollowing
      )
      userProfileView.dataApply(profile: profile, posts: $0.posts)
    }.disposed(by: disposeBag)

    // 태그 탭
    userProfileView.tagDidTap
      .map { tag in .goToTagDetail(tag) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 뒤로가기 탭
    userProfileView.backButton.rx.tap
      .map { .backButtonTap }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 팔로우 버튼 탭
    userProfileView.followDidTap
      .map { .followButtonTapped }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 리로딩
    reactor.doReload
      .observe(on: MainScheduler.instance)
      .bind { [userProfileView] in
        userProfileView.collectionView.reloadData()
      }.disposed(by: disposeBag)

    userProfileView.collectionView.rx.itemSelected
      .compactMap { [weak self] indexPath -> Post? in
        guard let self, let item = userProfileView.dataSource.itemIdentifier(for: indexPath)
        else { return nil }
        switch item {
        case .post(let post):
          return post
        default:
          return nil
        }
      }
      .map { post in .didTapPost(post) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    userProfileView.kebabButton.rx.tap
      .bind { [weak self] in
        guard let self = self else { return }
        let button = self.userProfileView.kebabButton
        let point = button.convert(button.bounds, to: self.view)
        menuView.show(in: view, sourcePoint: CGPoint(x: point.maxX - 120, y: point.maxY + 5))
      }
      .disposed(by: disposeBag)

    menuView.itemTap
      .bind { [weak self] index in
        guard let self else { return }
        switch index {
        case 0:
          let blockAlert = AlertView.makeAlert(style: .blockUser(nickname: reactor.user.nickname ?? ""))
          blockAlert.rightTap
            .map { .blockUser }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
          blockAlert.show(in: view)
        case 1:
          let reportAlert = AlertView.makeAlert(style: .reportUser(nickname: reactor.user.nickname ?? ""))
          reportAlert.rightTap
            .map { .reportUser }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
          reportAlert.show(in: view)
        default: break
        }
      }
      .disposed(by: disposeBag)
  }
}

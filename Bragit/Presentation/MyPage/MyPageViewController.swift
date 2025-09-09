//
//  MyPageViewController.swift
//  Bragit
//
//  Created by 이태윤 on 8/21/25.
//
import UIKit

import ReactorKit
import RxSwift
import RxCocoa

class MyPageViewController: UIViewController, View {
  var disposeBag = DisposeBag()

  private let myPageView = MyPageView()

  init(reactor: MyPageReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    view = myPageView
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    self.navigationController?.navigationBar.isHidden = true
  }

  func bind(reactor: MyPageReactor) {
    self.rx.viewWillAppear
      .flatMap {_ in
        Observable.from([
          .setUserInform,
          .loadMyPost
        ])
      }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    reactor.state.bind { [myPageView] in
      let profile = Profile(
        nickName: $0.nickName,
        profileImage: $0.profileImage,
        follwerCount: $0.followers.count,
        followingCount: $0.followings.count,
        favoriteTagCount: $0.favoriteTags.count,
        isFollowing: false
      )

      myPageView.dataApply(profile: profile, posts: $0.posts)
    }.disposed(by: disposeBag)

    myPageView.editNicknameTap.bind { [weak self] in
      guard let self = self else { return }
      let nicknameChangeVC = NickNameChangeViewController()

      nicknameChangeVC.completion = { [weak self] in
        guard let self = self else { return }
        self.reactor?.action.onNext(.setUserInform)
        self.reactor?.action.onNext(.loadMyPost)
      }

      if let sheet = nicknameChangeVC.sheetPresentationController {
        sheet.detents = [.large()]
      }
      self.present(nicknameChangeVC, animated: true)
    }.disposed(by: disposeBag)

    myPageView.settingButton.rx.tap
      .map { .goToSetting }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    myPageView.tagDidTap
      .map { tag in .goToTagDetail(tag) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    myPageView.followerTap
      .bind { reactor.action.onNext(.goToFollower) }
      .disposed(by: disposeBag)

    myPageView.followingTap
      .bind { reactor.action.onNext(.goToFollowing) }
      .disposed(by: disposeBag)

    myPageView.favoriteTagTap
      .bind { reactor.action.onNext(.goToFavoriteTag) }
      .disposed(by: disposeBag)

    myPageView.profileImageTap
      .bind(with: self) { owner, _ in
        owner.myPageView.imagePicker.delegate = owner
        owner.present(owner.myPageView.imagePicker, animated: true)
      }
      .disposed(by: disposeBag)

    myPageView.collectionView.rx.itemSelected
      .compactMap { [weak self] indexPath -> Post? in
        guard let self, let item = myPageView.dataSource.itemIdentifier(for: indexPath)
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
  }
}

extension MyPageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    picker.dismiss(animated: true)

    guard let image = info[.editedImage] as? UIImage else {
      return
    }

    reactor?.action.onNext(.registImage(image))
    myPageView.profileImageDidChange.accept(image)
    myPageView.imagePicker.delegate = nil
  }
}

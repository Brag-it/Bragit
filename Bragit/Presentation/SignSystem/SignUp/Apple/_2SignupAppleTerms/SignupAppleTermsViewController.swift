//
//  SignupAppleTermsViewController.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import UIKit

import ReactorKit
import RxCocoa
import RxSwift

//
//

final class SignupAppleTermsViewController: UIViewController, View {
  var disposeBag = DisposeBag()
  private let rootView = SignupAppleTermsView()

  override func loadView() {
    self.view = rootView
  }

  init(reactor: SignupAppleTermsReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: false)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
  }

  func bind(reactor: SignupAppleTermsReactor) {
    rootView.backButton.rx.tap
      .map { .tapBack }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    rootView.nextButton.rx.tap
      .map { .tapNext }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    rootView.serviceDetailButton.rx.tap
      .bind(with: self) { owner, _ in
        let item = TermsItem(name: "서비스 이용 약관", bundleFileName: "Terms_Service")
        owner.pushTermsDetail(item: item)
      }
      .disposed(by: disposeBag)

    rootView.privacyDetailButton.rx.tap
      .bind(with: self) { owner, _ in
        let item = TermsItem(name: "개인정보 수집 및 처리 방침", bundleFileName: "Terms_PersonalInfo")
        owner.pushTermsDetail(item: item)
      }
      .disposed(by: disposeBag)

    rootView.marketingDetailButton.rx.tap
      .bind(with: self) { owner, _ in
        let item = TermsItem(name: "마케팅 정보 수집 및 수신", bundleFileName: "Terms_Marketing")
        owner.pushTermsDetail(item: item)
      }
      .disposed(by: disposeBag)
  }
  func pushTermsDetail(item: TermsItem) {
    let viewController = SettingTermsDetailViewController(item: item)
    navigationController?.pushViewController(viewController, animated: true)
  }
}

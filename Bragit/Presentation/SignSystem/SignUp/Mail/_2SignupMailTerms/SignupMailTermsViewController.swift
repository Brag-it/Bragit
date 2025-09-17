//
//  SignupMailTermsViewController.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import ReactorKit
import RxCocoa
import RxSwift
import UIKit

// 이메일 가입 2단계
// 가입자에게 약관 동의를 받음. 완료 후에는 가입 승인 인증코드 발송

final class SignupMailTermsViewController: UIViewController {
  private let disposeBag = DisposeBag()
  private let rootView = SignupMailTermsView()

  override func loadView() {
    self.view = rootView
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: false)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    bind()
  }

  private func bind() {

  }
}

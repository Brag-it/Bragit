//
//  SignupMailConfirmViewController.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import ReactorKit
import RxCocoa
import RxSwift
import UIKit

// 이메일 가입 3단계
// 가입자에게 보낸 인증 코드를 입력 받고 확인 절차를 거침(가입 완료)

final class SignupMailConfirmViewController: UIViewController {
  private let disposeBag = DisposeBag()
  private let rootView = SignupMailConfirmView()

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

//
//  SignupMailInfoViewController.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import ReactorKit
import RxCocoa
import RxSwift
import UIKit

// 이메일 가입 1단계
// 가입자에게 이메일, 비밀번호, 비밀번호 확인, 닉네임을 입력 받음

final class SignupMailInfoViewController: UIViewController, View {
  var disposeBag = DisposeBag()
  private let rootView = SignupMailInfoView()

  override func loadView() {
    self.view = rootView
  }

  init(reactor: SignupMailInfoReactor) {
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

  func bind(reactor: SignupMailInfoReactor) {
    rootView.backButton.rx.tap
      .bind(with: self) { owner, _ in
        owner.navigationController?.popViewController(animated: true)
      }
      .disposed(by: disposeBag)

    rootView.mailTextField.rx.controlEvent(.editingDidEndOnExit)
      .bind(with: self) { owner, _ in
        owner.rootView.pwTextField.becomeFirstResponder()
      }
      .disposed(by: disposeBag)

    rootView.pwTextField.rx.controlEvent(.editingDidEndOnExit)
      .bind(with: self) { owner, _ in
        owner.rootView.rePwTextField.becomeFirstResponder()
      }
      .disposed(by: disposeBag)

    rootView.rePwTextField.rx.controlEvent(.editingDidEndOnExit)
      .bind(with: self) { owner, _ in
        owner.rootView.nicknameTextField.becomeFirstResponder()
      }
      .disposed(by: disposeBag)

    rootView.nicknameTextField.rx.controlEvent(.editingDidEndOnExit)
      .bind(with: self) { owner, _ in
        owner.rootView.nicknameTextField.resignFirstResponder()
      }
      .disposed(by: disposeBag)
  }
}

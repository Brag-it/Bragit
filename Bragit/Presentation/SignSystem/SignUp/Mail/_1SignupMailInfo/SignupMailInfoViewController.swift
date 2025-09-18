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

  // Validation state
  private var mailValid = false
  private var passwordValid = false
  private var confirmMatched = false
  private var nicknameValid = false

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
    bindValidation()
  }

  private func updateNextButton() {
    let enabled = mailValid && passwordValid && confirmMatched && nicknameValid
    rootView.setNextEnabled(enabled)
  }

  private func bindValidation() {
    rootView.mailTextField.addTarget(self, action: #selector(onMailEditingEnd), for: .editingDidEnd)
    rootView.pwTextField.addTarget(self, action: #selector(onPasswordEditingEnd), for: .editingDidEnd)
    rootView.rePwTextField.addTarget(self, action: #selector(onConfirmEditingEnd), for: .editingDidEnd)
    rootView.nicknameTextField.addTarget(self, action: #selector(onNicknameEditingEnd), for: .editingDidEnd)
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

    bindValidation()
  }

  @objc private func onMailEditingEnd() {
    let text = rootView.mailTextField.text ?? ""
    mailValid = MailInfoValidator.isValidMail(text)
    rootView.showMailValidity(isValid: mailValid)
    updateNextButton()
  }

  @objc private func onPasswordEditingEnd() {
    let pwdRaw = rootView.pwTextField.text ?? ""
    let confirmRaw = rootView.rePwTextField.text ?? ""
    let pwd = pwdRaw.trimmingCharacters(in: .whitespacesAndNewlines)
    let confirm = confirmRaw.trimmingCharacters(in: .whitespacesAndNewlines)

    passwordValid = MailInfoValidator.isValidPassword(pwd)
    if !confirm.isEmpty { confirmMatched = (pwd == confirm) }

    rootView.showPasswordValidity(isValid: passwordValid)
    if !confirm.isEmpty { rootView.showConfirmMatch(isMatched: confirmMatched) }
    updateNextButton()
  }

  @objc private func onConfirmEditingEnd() {
    let pwd = (rootView.pwTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let confirm = (rootView.rePwTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    confirmMatched = (pwd == confirm) && !pwd.isEmpty

    rootView.showConfirmMatch(isMatched: confirmMatched)
    updateNextButton()
  }

  @objc private func onNicknameEditingEnd() {
    let name = rootView.nicknameTextField.text ?? ""
    nicknameValid = MailInfoValidator.isValidNickname(name)
    rootView.showNicknameValidity(isValid: nicknameValid)
    updateNextButton()
  }
}

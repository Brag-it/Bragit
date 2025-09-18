//
//  SignupMailInfoViewController.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import UIKit

import ReactorKit
import RxCocoa
import RxSwift

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

    let mailText = rootView.mailTextField.rx.text.orEmpty.share(replay: 1)
    let pwText = rootView.pwTextField.rx.text.orEmpty.map {
      $0.trimmingCharacters(in: .whitespacesAndNewlines)
    }.share(replay: 1)
    let confirmText = rootView.rePwTextField.rx.text.orEmpty.map {
      $0.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    .share(replay: 1)
    let nicknameText = rootView.nicknameTextField.rx.text.orEmpty.share(replay: 1)

    rootView.nextButton.rx.tap
      .withLatestFrom(Observable.combineLatest(mailText, pwText, nicknameText))
      .map { mail, password, nickname in
        SignupMailInfoReactor.Action.tapNext(mail: mail, password: password, nickname: nickname)
      }
      .bind(to: reactor.action)
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

    let mailEditingEnd = rootView.mailTextField.rx.controlEvent(.editingDidEnd).share()
    let pwEditingEnd = rootView.pwTextField.rx.controlEvent(.editingDidEnd).share()
    let confirmEditingEnd = rootView.rePwTextField.rx.controlEvent(.editingDidEnd).share()
    let nicknameEditingEnd = rootView.nicknameTextField.rx.controlEvent(.editingDidEnd).share()

    let mailValid =
      mailEditingEnd
      .withLatestFrom(mailText)
      .map { MailInfoValidator.isValidMail($0) }
      .do { [weak self] isValid in
        self?.rootView.showMailValidity(isValid: isValid)
      }
      .startWith(false)
      .share(replay: 1)

    let passwordValid =
      pwEditingEnd
      .withLatestFrom(pwText)
      .map { MailInfoValidator.isValidPassword($0) }
      .do { [weak self] isValid in
        self?.rootView.showPasswordValidity(isValid: isValid)
      }
      .startWith(false)
      .share(replay: 1)

    let confirmMatched = Observable.merge(pwEditingEnd, confirmEditingEnd)
      .withLatestFrom(Observable.combineLatest(pwText, confirmText))
      .map { pwd, confirm in (pwd == confirm) && !pwd.isEmpty }
      .do { [weak self] isMatched in
        self?.rootView.showConfirmMatch(isMatched: isMatched)
      }
      .startWith(false)
      .share(replay: 1)

    let nicknameValid =
      nicknameEditingEnd
      .withLatestFrom(nicknameText)
      .map { MailInfoValidator.isValidNickname($0) }
      .do { [weak self] isValid in
        self?.rootView.showNicknameValidity(isValid: isValid)
      }
      .startWith(false)
      .share(replay: 1)

    Observable.combineLatest(
      mailValid,
      passwordValid,
      confirmMatched,
      nicknameValid
    ) { $0 && $1 && $2 && $3 }
    .distinctUntilChanged()
    .bind(with: self) { owner, enabled in
      owner.rootView.setNextEnabled(enabled)
    }
    .disposed(by: disposeBag)
  }
}

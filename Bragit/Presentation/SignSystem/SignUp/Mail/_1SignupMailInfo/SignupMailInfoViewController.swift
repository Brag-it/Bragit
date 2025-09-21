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

  private struct NicknameStatus: Equatable {
    let valid: Bool
    let text: String
  }

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
      .map { .tapBack }
      .bind(to: reactor.action)
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
      .withLatestFrom(
        Observable.combineLatest(
          rootView.mailTextField.rx.text.orEmpty,
          rootView.pwTextField.rx.text.orEmpty,
          rootView.nicknameTextField.rx.text.orEmpty
        )
      )
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
      .map { AppleInfoValidator.isValidMail($0) }
      .do { [weak self] isValid in
        self?.rootView.showMailValidity(isValid: isValid)
      }
      .startWith(false)
      .share(replay: 1)

    let passwordValid =
      pwEditingEnd
      .withLatestFrom(pwText)
      .map { AppleInfoValidator.isValidPassword($0) }
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

    let nicknameOnEnd = nicknameEditingEnd
      .withLatestFrom(nicknameText)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .share(replay: 1)

    nicknameOnEnd
      .bind(with: self) { owner, name in
        owner.reactor?.action.onNext(.validateNickname(name))
      }
      .disposed(by: disposeBag)

    let nicknameStatusStream = reactor.state
      .map { state -> NicknameStatus in
        NicknameStatus(valid: state.nicknameValid, text: state.nicknameStatusText)
      }
      .distinctUntilChanged()
      .observe(on: MainScheduler.instance)

    nicknameStatusStream
      .bind(with: self) { owner, status in
        let text = status.text
        let style: SignupMailInfoView.NicknameStatusStyle
        switch text {
        case "중복 확인 중...": style = .loading
        case "사용 가능한 닉네임입니다": style = .accept
        case " ": style = .none
        default: style = .reject
        }
        owner.rootView.setNicknameStatus(style: style, message: text)
      }
      .disposed(by: disposeBag)

    let nicknameValidFromState = reactor.state.map { $0.nicknameValid }.distinctUntilChanged().share(replay: 1)

    Observable.combineLatest(
      mailValid,
      passwordValid,
      confirmMatched,
      nicknameValidFromState
    ) { $0 && $1 && $2 && $3 }
    .distinctUntilChanged()
    .bind(with: self) { owner, enabled in
      owner.rootView.setNextEnabled(enabled)
    }
    .disposed(by: disposeBag)
  }
}


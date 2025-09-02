//
//  LoginViewController.swift
//  Bragit
//
//  Created by luca on 8/21/25.
//

import AuthenticationServices
import CryptoKit
import UIKit

import ReactorKit
import RxCocoa
import RxSwift
import SnapKit
import Then

final class LoginViewController: UIViewController, View {
  let loginFont = UIFont.pretendard(size: 14, weight: .medium)
  let signUpFont = UIFont.pretendard(size: 13, weight: .medium)
  //  private var currentNonce: String?
  var disposeBag = DisposeBag()

  // MARK: - 임시 버튼
  private let nextButton = UIButton(type: .system).then {
    $0.setTitle("Next", for: .normal)
  }

  // MARK: UI
  // 버튼은 어차피 나중에 api로 제공되니 임시로 넣은 것
  let googleButton = UIButton(type: .system).then {
    $0.layer.cornerRadius = 12
    $0.backgroundColor = .white
    $0.setTitle("Google로 로그인(아직)", for: .normal)
  }

  let kakaoButton = UIButton(type: .system).then {
    $0.layer.cornerRadius = 12
    $0.backgroundColor = UIColor(red: 0.996, green: 0.898, blue: 0, alpha: 1)
    $0.setTitle("카카오로 로그인􀀲", for: .normal)
  }

  let appleButton = ASAuthorizationAppleIDButton(type: .signIn, style: .black).then {
    $0.cornerRadius = 12
  }

  let mailButton = UIButton(type: .system).then {
    var config = UIButton.Configuration.gray()
    config.title = "이메일로 로그인(미구현)"
    $0.setTitleColor(UIColor(red: 0.439, green: 0.439, blue: 0.439, alpha: 1), for: .normal)
    config.image = .mail
    config.imagePlacement = .leading
    config.imagePadding = 5
    $0.configuration = config
    $0.layer.cornerRadius = 12
    $0.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1)
  }

  let signUpButton = UIButton(type: .system).then {
    $0.setTitle("회원 가입하기", for: .normal)
    $0.setTitleColor(UIColor(red: 0.439, green: 0.439, blue: 0.439, alpha: 1), for: .normal)
  }

  init(reactor: LoginReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: viewDidLoad
  override func viewDidLoad() {
    super.viewDidLoad()
    // TODO: 테스트
    //    title = "로그인"
    view.backgroundColor = .systemBackground

    //    if reactor == nil { reactor = LoginReactor() }

    setupLayout()
  }

  // MARK: LAYOUT
  private func setupLayout() {
    view.addSubview(nextButton)
    //    let stack = UIStackView(arrangedSubviews: [appleButton, googleButton, kakaoButton, mailButton]).then {
    let stack = UIStackView(arrangedSubviews: [appleButton, googleButton, mailButton]).then {
      $0.axis = .vertical
      $0.spacing = 10
      $0.alignment = .fill
      $0.distribution = .fill
    }

    view.addSubview(stack)
    view.addSubview(signUpButton)
    mailButton.titleLabel?.font = loginFont
    signUpButton.titleLabel?.font = signUpFont

    [nextButton, appleButton, googleButton, kakaoButton, mailButton].forEach {
      $0.snp.makeConstraints {
        $0.height.equalTo(48)
      }
    }

    nextButton.snp.makeConstraints {
      $0.bottom.equalTo(stack.snp.top).offset(-32)
      $0.leading.trailing.equalTo(stack)
    }

    stack.snp.makeConstraints {
      $0.bottom.equalTo(signUpButton.snp.top).offset(-32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    signUpButton.snp.makeConstraints {
      $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
      $0.centerX.equalToSuperview()
    }
  }

  // MARK: Reactor Binding
  func bind(reactor: LoginReactor) {
    // 디버그 강제 홈 이동 버튼
    nextButton.rx.tap
      .subscribe(with: reactor) { reactor, _ in
        reactor.action.onNext(.tapNext)
      }
      .disposed(by: disposeBag)

    // 애플 로그인 버튼
    appleButton.rx.controlEvent(.touchUpInside)
      .subscribe(with: reactor) { reactor, _ in
        reactor.action.onNext(.tapAppleButton)
      }
      .disposed(by: disposeBag)

    // 회원가입 버튼
    signUpButton.rx.controlEvent(.touchUpInside)
      .subscribe(with: self) { owner, _ in
        //        KeychainMailStore.clear()
        owner.reactor?.action.onNext(.tapSignUp)
      }
      .disposed(by: disposeBag)

    // state -> ui
    // state에서 이미 된 건 VC에서 observer(on: MainScheduler.instance)를 쓰지 않고 Reactor에서
    //    func transform(state: Observable<State>) -> Observable<State> {
    //      state.observe(on: MainScheduler.instance)
    //    }
    // 위 코드를 넣는 것으로 대체 가능
    reactor.state.compactMap(\.appleHashsedNonce)
      .distinctUntilChanged()
      .subscribe { [weak self] hashed in
        self?.startAppleFlow(hashedNonce: hashed)
      }
      .disposed(by: disposeBag)

    reactor.state.compactMap(\.errorMessage)
      .subscribe { [weak self] msg in
        self?.alert(msg)
      }
      .disposed(by: disposeBag)
  }
}

// MARK: Apple UI
extension LoginViewController:
  ASAuthorizationControllerDelegate,
  ASAuthorizationControllerPresentationContextProviding {
  private func startAppleFlow(hashedNonce: String) {
    let request = ASAuthorizationAppleIDProvider().createRequest()
    request.requestedScopes = [.fullName, .email]
    //    request.nonce = sha256(nonce)
    request.nonce = hashedNonce

    let controller = ASAuthorizationController(authorizationRequests: [request])
    controller.delegate = self
    controller.presentationContextProvider = self
    controller.performRequests()
  }

  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    view.window ?? ASPresentationAnchor()
  }

  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
  ) {
    guard
      let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
      let tokenData = credential.identityToken,
      let idToken = String(data: tokenData, encoding: .utf8),
      let reactor,
      let nonce = reactor.currentState.appleNonce
    else {
      alert("Apple 자격이 유효하지 않습니다.")
      return
    }
    let rawMail = credential.email?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let rawMail, !rawMail.isEmpty { KeychainMailStore.save(rawMail) }
    let mail = (rawMail?.isEmpty == false) ? rawMail : KeychainMailStore.load()
    reactor.action.onNext(.tapApple(idToken: idToken, nonce: nonce, mail: mail))
  }

  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithError error: Error
  ) {
    alert("Apple 로그인 실패: \(error.localizedDescription)")
  }

  func handleAppleCredential(
    _ credential: ASAuthorizationAppleIDCredential,
    reactor: LoginReactor,
    hashedNonce: String
  ) {
    if let email = credential.email {
      KeychainMailStore.save(email)
    }
    let initialMail = credential.email ?? KeychainMailStore.load()
    guard let idTokenData = credential.identityToken, let idToken = String(data: idTokenData, encoding: .utf8) else {
      return
    }
    reactor.action.onNext(.tapApple(idToken: idToken, nonce: hashedNonce, mail: initialMail))
  }
}

extension LoginViewController {
  private func alert(_ message: String) {
    let alertController = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
    alertController.addAction(.init(title: "OK", style: .default))
    present(alertController, animated: true)
  }
}

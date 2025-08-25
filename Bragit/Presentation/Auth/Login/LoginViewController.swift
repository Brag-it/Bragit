//
//  LoginViewController.swift
//  Bragit
//
//  Created by luca on 8/21/25.
//

import AuthenticationServices
import CryptoKit
import ReactorKit
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class LoginViewController: UIViewController, View {
  let loginFont = UIFont.pretendard(size: 14, weight: .medium)
  let signUpFont = UIFont.pretendard(size: 13, weight: .medium)
  //  private var currentNonce: String?
  var disposeBag = DisposeBag()
  private let reactor = LoginReactor()

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
    view.backgroundColor = .systemBackground

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

    [appleButton, googleButton, kakaoButton, mailButton].forEach {
      $0.snp.makeConstraints {
        $0.height.equalTo(48)
      }
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
    appleButton.rx.controlEvent(.touchUpInside)
      .subscribe(with: reactor) { reactor, _ in
        reactor.action.onNext(.tapAppleButton)
      }
      .disposed(by: disposeBag)

    // state -> ui
    reactor.state.compactMap(\.appleHashsedNonce)
      .distinctUntilChanged()
      .observe(on: MainScheduler.instance)
      .subscribe { [weak self] hashed in
        self?.startAppleFlow(hashedNonce: hashed)
      }
      .disposed(by: disposeBag)

    reactor.state.compactMap(\.errorMessage)
      .observe(on: MainScheduler.instance)
      .subscribe { [weak self] msg in
        self?.alert(msg)
      }
      .disposed(by: disposeBag)

    reactor.state.compactMap(\.route)
      .distinctUntilChanged()
      .observe(on: MainScheduler.instance)
      .subscribe { [weak self] event in
        if case .next(let route) = event {
          switch route {
          case .signInIsComplete:
            let viewController = UIViewController()
            viewController.title = "메인"
            self?.navigationController?.setViewControllers([viewController], animated: true)
          }
        }
      }
      .disposed(by: disposeBag)
  }
}

// MARK: Apple UI
extension LoginViewController:
  ASAuthorizationControllerDelegate,
  ASAuthorizationControllerPresentationContextProviding {
  //  private func startAppleFlow() {
  //    let nonce = randomNonce()
  //    currentNonce = nonce
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
      //      let nonce = currentNonce,
      let reactor,
      let nonce = reactor.currentState.appleNonce
    else {
      alert("Apple 자격이 유효하지 않습니다.")
      return
    }
    reactor.action.onNext(.tapApple(idToken: idToken, nonce: nonce))
  }

  func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithError error: Error
  ) {
    alert("Apple 로그인 실패: \(error.localizedDescription)")
  }
}

extension LoginViewController {
  // nonce: Number Used Once
  // Sign in with Apple에서 권장(nonce 생성 및 해시 적용)

  // nonce 생성(32자 랜덤 문자열 생성)
  //  fileprivate func randomNonce(length: Int = 32) -> String {
  //    precondition(length > 0)
  //    let charSet: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
  //    var result = ""
  //    var remaining = length
  //
  //    while remaining > 0 {
  //      var random: UInt8 = 0
  //      let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
  //      if status != errSecSuccess { fatalError("Unable to generate nonce.") }
  //      if random < charSet.count {
  //        result.append(charSet[Int(random % UInt8(charSet.count))])
  //        remaining -= 1
  //      }
  //    }
  //    return result
  //  }
  //
  //  // nonce -> 해시 변환
  //  fileprivate func sha256(_ input: String) -> String {
  //    let inputData = Data(input.utf8)
  //    let hashed = SHA256.hash(data: inputData)
  //    return hashed.compactMap { String(format: "%02x", $0) }.joined()
  //  }

  fileprivate func alert(_ message: String) {
    let alertController = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
    alertController.addAction(.init(title: "OK", style: .default))
    present(alertController, animated: true)
  }
}

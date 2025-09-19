//
//  SignupAppleNicknameViewController.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import UIKit

import ReactorKit
import RxCocoa
import RxSwift

// 이메일 가입 5단계
// 가입자에게 관심있는 태그를 선택할 수 있는 선택지를 줌

final class SignupAppleNicknameViewController: UIViewController, View {
  var disposeBag = DisposeBag()
  private let rootView = SignupAppleNicknameView()

  override func loadView() {
    self.view = rootView
  }

  init(reactor: SignupAppleNicknameReactor) {
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

    // Dismiss keyboard on background tap
    let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)

    // Ensure return key dismisses keyboard
    rootView.nicknameTextField.delegate = self
  }

  func bind(reactor: SignupAppleNicknameReactor) {
    rootView.backButton.rx.tap
      .map { SignupAppleNicknameReactor.Action.tapBack }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    rootView.nextButton.rx.tap
      .withLatestFrom(rootView.nicknameTextField.rx.text.orEmpty)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .map { SignupAppleNicknameReactor.Action.tapNext($0) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    rootView.nicknameTextField.addTarget(self, action: #selector(onNicknameEditingEnd), for: .editingDidEnd)

    reactor.state
      .observe(on: MainScheduler.instance)
      .bind(with: self) { owner, state in
        owner.rootView.setNicknameStatus(style: owner.mapStyle(state.statusStyle), message: state.statusText)
        owner.rootView.nextButton.isEnabled = state.nextEnabled
        owner.rootView.nextButton.alpha = state.nextEnabled ? 1.0 : 0.5
      }
      .disposed(by: disposeBag)
  }

  @objc private func onNicknameEditingEnd() {
    let name = ownerSafeTrim(rootView.nicknameTextField.text)
    guard !name.isEmpty else { return }
    reactor?.action.onNext(.validateNickname(name))
  }

  private func ownerSafeTrim(_ text: String?) -> String {
    return (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func mapStyle(_ style: SignupAppleNicknameReactor.StatusStyle) -> SignupAppleNicknameView.StatusStyle {
    switch style {
    case .none: return .none
    case .loading: return .loading
    case .accept: return .accept
    case .reject: return .reject
    }
  }
}

extension SignupAppleNicknameViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }

  @objc func dismissKeyboard() {
    view.endEditing(true)
  }
}

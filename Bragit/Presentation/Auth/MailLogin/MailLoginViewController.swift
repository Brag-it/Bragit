//
//  MailLoginViewController.swift
//  Bragit
//
//  Created by luca on 9/9/25.
//

import UIKit

import ReactorKit
import RxCocoa
import RxSwift
import SnapKit
import Then

final class MailLoginViewController: UIViewController, View {
  typealias Reactor = MailLoginReactor
  var disposeBag = DisposeBag()

  private let headerView = UIView()
  private let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }

  private let headerLabel = UILabel().then {
    $0.text = "로그인"
    $0.font = UIFont.systemFont(ofSize: 16)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
  }

  private let scrollView = UIScrollView().then {
    $0.keyboardDismissMode = .interactive
    $0.alwaysBounceVertical = true
    $0.showsVerticalScrollIndicator = false
    $0.contentInsetAdjustmentBehavior = .never
  }

  private let contentView = UIView()

  private let mailLabel = UILabel().then {
    $0.text = "이메일"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale700
  }

  private let mailTextField = InsetTextField().then {
    $0.placeholder = "Bragit@bragit.com"
    $0.font = .pretendard(size: 14, weight: .regular)
    $0.textColor = .grayScale900
    $0.backgroundColor = .white
    $0.layer.cornerRadius = 14
    $0.layer.borderWidth = 1
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.clearButtonMode = .whileEditing
    $0.autocapitalizationType = .none
    $0.autocorrectionType = .no
    $0.spellCheckingType = .no
    $0.keyboardType = .emailAddress
    $0.returnKeyType = .next
  }

  private let passwordLabel = UILabel().then {
    $0.text = "비밀번호"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale700
  }

  private let passwordTextField = InsetTextField().then {
    $0.placeholder = "8-24자 사이 영문, 숫자, 특수문자"
    $0.font = .pretendard(size: 14, weight: .regular)
    $0.textColor = .grayScale900
    $0.backgroundColor = .white
    $0.layer.cornerRadius = 14
    $0.layer.borderWidth = 1
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.clearButtonMode = .whileEditing
    $0.isSecureTextEntry = true
    $0.autocorrectionType = .no
    $0.spellCheckingType = .no
    $0.textContentType = .password
    $0.returnKeyType = .done
  }

  private let loginButton = UIButton(type: .system).then {
    $0.setTitle("확인", for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16, weight: .medium)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.backgroundColor = .primary400
    $0.layer.cornerRadius = 12
    $0.isEnabled = false
    $0.alpha = 0.5
  }

  private let forgotPasswordButton = UIButton(type: .system).then {
    $0.setTitle("비밀번호를 잊으셨나요?", for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16, weight: .regular)
    $0.setTitleColor(.grayScale700, for: .normal)
    $0.contentHorizontalAlignment = .center
  }

  private let activityIndicator = UIActivityIndicatorView(style: .medium).then {
    $0.hidesWhenStopped = true
    $0.isUserInteractionEnabled = false
  }

  private lazy var dismissTapGesture: UITapGestureRecognizer = {
    let tap = UITapGestureRecognizer()
    tap.cancelsTouchesInView = false
    return tap
  }()

  init(reactor: MailLoginReactor) {
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
    view.backgroundColor = .systemBackground
    setupLayout()
    view.addGestureRecognizer(dismissTapGesture)
    mailTextField.delegate = self
    passwordTextField.delegate = self
  }

  private func setupLayout() {
    view.addSubview(headerView)
    headerView.addSubview(backButton)
    headerView.addSubview(headerLabel)
    view.addSubview(scrollView)
    scrollView.addSubview(contentView)
    view.addSubview(activityIndicator)

    [mailLabel, mailTextField, passwordLabel, passwordTextField, loginButton, forgotPasswordButton].forEach {
      contentView.addSubview($0)
    }

    headerView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(58)
    }

    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(20)
      $0.centerY.equalToSuperview()
    }

    headerLabel.snp.makeConstraints {
      $0.centerX.centerY.equalToSuperview()
    }

    scrollView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom)
      $0.leading.trailing.bottom.equalToSuperview()
    }

    contentView.snp.makeConstraints {
      $0.edges.equalTo(scrollView.contentLayoutGuide)
      $0.width.equalTo(scrollView.frameLayoutGuide)
      // height 제약 제거: 맨 마지막 뷰의 bottom으로 콘텐츠 높이 확정
    }

    mailLabel.snp.makeConstraints {
      $0.top.equalTo(contentView.snp.top).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    mailTextField.snp.makeConstraints {
      $0.top.equalTo(mailLabel.snp.bottom).offset(8)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }

    passwordLabel.snp.makeConstraints {
      $0.top.equalTo(mailTextField.snp.bottom).offset(20)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    passwordTextField.snp.makeConstraints {
      $0.top.equalTo(passwordLabel.snp.bottom).offset(8)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }

    loginButton.snp.makeConstraints {
      $0.top.equalTo(passwordTextField.snp.bottom).offset(48)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(36)
    }

    forgotPasswordButton.snp.makeConstraints {
      $0.top.equalTo(loginButton.snp.bottom).offset(36)
      $0.leading.trailing.equalToSuperview()
      // centerX 제거(수평 중복 제약 방지), 아래 제약으로 콘텐츠 높이 결정
      $0.bottom.equalToSuperview().inset(24)
    }

    activityIndicator.snp.makeConstraints {
      $0.center.equalToSuperview()
    }
  }

  func bind(reactor: MailLoginReactor) {
    backButton.rx.tap
      .map { Reactor.Action.tapBack }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    mailTextField.rx.text.orEmpty
      .distinctUntilChanged()
      .map { Reactor.Action.updateEmail($0) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    passwordTextField.rx.text.orEmpty
      .distinctUntilChanged()
      .map { Reactor.Action.updatePassword($0) }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    loginButton.rx.tap
      .map { Reactor.Action.tapLogin }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    forgotPasswordButton.rx.tap
      .map { Reactor.Action.tapForgotPassword }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    dismissTapGesture.rx.event
      .bind { [weak self] _ in
        self?.view.endEditing(true)
      }
      .disposed(by: disposeBag)

    reactor.state.map { $0.canLogin }
      .distinctUntilChanged()
      .bind { [weak self] canLogin in
        self?.loginButton.isEnabled = canLogin
        self?.loginButton.alpha = canLogin ? 1.0 : 0.5
      }
      .disposed(by: disposeBag)

    reactor.state.map { $0.isLoading }
      .distinctUntilChanged()
      .bind { [weak self] isLoading in
        if isLoading {
          self?.activityIndicator.startAnimating()
        } else {
          self?.activityIndicator.stopAnimating()
        }
        self?.view.isUserInteractionEnabled = !isLoading
      }
      .disposed(by: disposeBag)

    // 안전한 Alert 표시: 메인 스레드 보장, 중복/타이밍 이슈 방지
    reactor.state
      .map { $0.errorMessage }
      .distinctUntilChanged { $0 == $1 } // 동일 메시지 중복 방지
      .compactMap { $0 }
      .observe(on: MainScheduler.instance)
      .withUnretained(self)
      .bind { viewController, message in
        guard viewController.isViewLoaded, viewController.view.window != nil else { return }
        guard viewController.presentedViewController == nil else { return }

        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "확인", style: .default))
        viewController.present(alert, animated: true)
      }
      .disposed(by: disposeBag)
  }
}

extension MailLoginViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == mailTextField {
      passwordTextField.becomeFirstResponder()
    } else if textField == passwordTextField {
      if reactor?.currentState.canLogin == true {
        reactor?.action.onNext(.tapLogin)
      }
      textField.resignFirstResponder()
    }
    return true
  }
}

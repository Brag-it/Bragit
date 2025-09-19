  //
  //  ConfirmPopupView.swift
  //  Bragit
  //
  //  Created by luca on 9/17/25.
  //

import UIKit

import SnapKit
import Then
import Dependencies
import Supabase

final class ConfirmPopupView: UIView {
  @Dependency(\.supabase) private var supabase

    // MARK: - Public Closures

  var onLeftTap: (() -> Void)?
  var onRightTap: (() -> Void)?

    // MARK: - Private UI

  private let dimmedView = UIView().then {
    $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    $0.alpha = 0
  }

  private let containerView = UIView().then {
    $0.backgroundColor = .white
    $0.layer.cornerRadius = 14
    $0.clipsToBounds = true
  }

  private let titleLabel = UILabel().then {
    $0.font = .pretendard(size: 16, weight: .semibold)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
    $0.numberOfLines = 0
  }

  private let messageLabel = UILabel().then {
    $0.font = .pretendard(size: 15, weight: .regular)
    $0.textColor = .grayScale600
    $0.numberOfLines = 5
  }

  private lazy var leftButton = UIButton(type: .system).then {
    $0.titleLabel?.font = .pretendard(size: 15, weight: .medium)
    $0.setTitleColor(.grayScale400, for: .normal)
    $0.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)
  }

  private lazy var rightButton = UIButton(type: .system).then {
    $0.titleLabel?.font = .pretendard(size: 16, weight: .medium)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.addTarget(self, action: #selector(rightButtonTapped), for: .touchUpInside)
  }

  private lazy var buttonStack = UIStackView(arrangedSubviews: [leftButton, rightButton]).then {
    $0.axis = .horizontal
    $0.distribution = .fillEqually
  }

    // MARK: - Init

  init(
    title: String,
    message: String,
    leftTitle: String = "재전송",
    rightTitle: String = "닫기"
  ) {
    super.init(frame: .zero)
    titleLabel.text = title
    messageLabel.text = message
    leftButton.setTitle(leftTitle, for: .normal)
    rightButton.setTitle(rightTitle, for: .normal)
    setupViews()
    setupConstraints()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

    // MARK: - Setup

  private func setupViews() {
    addSubview(dimmedView)
    addSubview(containerView)

    containerView.addSubview(titleLabel)
    containerView.addSubview(messageLabel)
    containerView.addSubview(buttonStack)
  }

  private func setupConstraints() {
    dimmedView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }

    containerView.snp.makeConstraints {
      $0.center.equalToSuperview()
      $0.width.equalTo(280)
        // $0.leading.greaterThanOrEqualToSuperview().offset(24)
        // $0.trailing.lessThanOrEqualToSuperview().inset(24)
    }

    titleLabel.snp.makeConstraints {
      $0.top.equalToSuperview().offset(20)
      $0.leading.trailing.equalToSuperview().inset(24)
    }

    messageLabel.snp.makeConstraints {
      $0.top.equalTo(titleLabel.snp.bottom).offset(16)
      $0.leading.trailing.equalToSuperview().inset(24)
    }

    buttonStack.snp.makeConstraints {
      $0.top.equalTo(messageLabel.snp.bottom).offset(10)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(53)
      $0.bottom.equalToSuperview()
    }
  }

    // MARK: - Actions

  @objc private func leftButtonTapped() {
      // 재전송: Keychain에 저장된 이메일로 OTP 재발송
    Task { [weak self] in
      guard let self else { return }
      do {
        if let email = KeychainMailStore.load(), !email.isEmpty {
          try await self.supabase.auth.signInWithOTP(email: email, shouldCreateUser: true)
        } else {
          print("[ConfirmPopup] No email in Keychain to resend OTP")
        }
      } catch {
        print("[ConfirmPopup] Resend OTP failed: \(error)")
      }
        // 콜백 실행 및 닫기
      self.onLeftTap?()
    }
  }

  @objc private func rightButtonTapped() {
    onRightTap?()
  }

    // MARK: - Public Methods

  public func setLeftButtonTitle(_ title: String) {
    if leftButton.title(for: .normal) == title { return }
    UIView.performWithoutAnimation {
      self.leftButton.setTitle(title, for: .normal)
      self.leftButton.layoutIfNeeded()
    }
  }

  public func setLeftButtonEnabled(_ enabled: Bool) {
    UIView.performWithoutAnimation {
      self.leftButton.isEnabled = enabled
      self.leftButton.alpha = enabled ? 1.0 : 0.5
      self.leftButton.layoutIfNeeded()
    }
  }

    // MARK: - Convenience

  static func present(
    on view: UIView,
    title: String,
    message: String,
    leftTitle: String = "취소",
    rightTitle: String = "확인",
    leftAction: (() -> Void)? = nil,
    rightAction: (() -> Void)? = nil
  ) {
    let popup = ConfirmPopupView(title: title, message: message, leftTitle: leftTitle, rightTitle: rightTitle)
    popup.onLeftTap = {
      leftAction?()
      popup.dismiss()
    }
    popup.onRightTap = {
      rightAction?()
      popup.dismiss()
    }
    popup.show(in: view)
  }

  func show(in view: UIView) {
    frame = view.bounds
    alpha = 0
    view.addSubview(self)

    UIView.animate(withDuration: 0.25) {
      self.alpha = 1
      self.dimmedView.alpha = 1
    }
  }

  func dismiss() {
    UIView.animate(
      withDuration: 0.25,
      animations: {
        self.alpha = 0
        self.dimmedView.alpha = 0
      },
      completion: { _ in
        self.removeFromSuperview()
      }
    )
  }
}

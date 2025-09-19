//
//  SignupMailInfoView.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import Foundation

import SnapKit
import Then
import UIKit

final class SignupMailInfoView: UIView {

  // MARK: - Header
  private let headerView = UIView()
  let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }
  private let headerLabel = UILabel().then {
    $0.text = "회원가입"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
  }

  // MARK: - Scroll
  private let scrollView = UIScrollView().then {
    $0.keyboardDismissMode = .interactive
    $0.alwaysBounceVertical = true
    $0.showsVerticalScrollIndicator = true
    $0.delaysContentTouches = false
  }
  private let contentView = UIView().then { $0.backgroundColor = .clear }

  // MARK: - Title
  private let descriptionTitleLabel = UILabel().then {
    $0.text = "로그인에 사용할 이메일과\n비밀번호를 입력해 주세요"
    $0.numberOfLines = 2
    $0.lineBreakMode = .byWordWrapping
    $0.setContentHuggingPriority(.required, for: .vertical)
    $0.setContentCompressionResistancePriority(.required, for: .vertical)
    $0.font = .pretendard(size: 20, weight: .semibold)
    $0.textColor = .grayScale900
  }

  // MARK: - Email
  private let mailLabel = UILabel().then {
    $0.text = "이메일"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale700
  }
  let mailTextField = InsetTextField().then {
    $0.placeholder = "bragit@bragit.com"
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 14
    $0.clearButtonMode = .whileEditing
    $0.font = .pretendard(size: 14, weight: .regular)
    $0.textColor = .grayScale900
    $0.returnKeyType = .next
    $0.autocapitalizationType = .none
    $0.spellCheckingType = .no
    $0.autocorrectionType = .no
    $0.textContentType = .emailAddress
  }
  private let mailCheckIcon = UIImageView().then {
    $0.contentMode = .scaleAspectFit
  }
  private let mailCheckLabel = UILabel().then {
    $0.text = "인증 완료된 이메일입니다"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .systemSafe
  }
  private let mailCheckStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 4
    $0.alignment = .leading
  }
  private let mailStack = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 8
  }

  // MARK: - Password
  private let pwLabel = UILabel().then {
    $0.text = "비밀번호"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale700
  }
  let pwTextField = InsetTextField().then {
    $0.placeholder = "8-24자 사이 영문, 숫자, 특수문자"
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 14
    $0.isSecureTextEntry = true
    $0.textContentType = .oneTimeCode
    $0.clearButtonMode = .whileEditing
    $0.font = .pretendard(size: 14, weight: .regular)
    $0.textColor = .grayScale900
    $0.returnKeyType = .next
    $0.spellCheckingType = .no
    $0.autocorrectionType = .no
    $0.autocapitalizationType = .none
  }
  private let pwCheckIcon = UIImageView().then { $0.contentMode = .scaleAspectFit }
  private let pwCheckLabel = UILabel().then {
    $0.text = " "
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .systemSafe
  }
  private let pwCheckStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 4
    $0.alignment = .leading
  }
  private let pwStack = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 8
  }

  // MARK: - Re-Password
  private let rePwLabel = UILabel().then {
    $0.text = "비밀번호 확인"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale700
  }
  let rePwTextField = InsetTextField().then {
    $0.placeholder = "8-24자 사이 영문, 숫자, 특수문자"
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 14
    $0.isSecureTextEntry = true
    $0.textContentType = .oneTimeCode
    $0.clearButtonMode = .whileEditing
    $0.font = .pretendard(size: 14, weight: .regular)
    $0.textColor = .grayScale900
    $0.returnKeyType = .next
    $0.spellCheckingType = .no
    $0.autocorrectionType = .no
    $0.autocapitalizationType = .none
  }
  private let rePwCheckIcon = UIImageView().then { $0.contentMode = .scaleAspectFit }
  private let rePwCheckLabel = UILabel().then {
    $0.text = " "
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .systemSafe
  }
  private let rePwCheckStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 4
    $0.alignment = .leading
  }
  private let rePwStack = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 8
  }

  // MARK: - Nickname
  private let nicknameLabel = UILabel().then {
    $0.text = "닉네임"
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .grayScale700
  }
  let nicknameTextField = InsetTextField().then {
    $0.placeholder = "2-8글자 내로 공백 없이 입력해 주세요"
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 14
    $0.clearButtonMode = .whileEditing
    $0.font = .pretendard(size: 14, weight: .regular)
    $0.textColor = .grayScale900
    $0.returnKeyType = .done
    $0.autocapitalizationType = .none
    $0.spellCheckingType = .no
    $0.autocorrectionType = .no
  }
  private let nicknameCheckIcon = UIImageView().then { $0.contentMode = .scaleAspectFit }
  private let nicknameCheckLabel = UILabel().then {
    $0.text = " "
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .systemSafe
  }
  private let nicknameCheckStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 4
    $0.alignment = .leading
  }
  private let nicknameStack = UIStackView().then {
    $0.axis = .vertical
    $0.spacing = 8
  }

  let nextButton = UIButton(type: .system).then {
    $0.setTitle("다음", for: .normal)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16, weight: .medium)
    $0.layer.cornerRadius = 12
    $0.isEnabled = false
    $0.backgroundColor = .primary400
  }

  // MARK: - Validation UI API
  func showMailValidity(isValid: Bool) {
    if isCheckingEmail { return }

    let raw = mailTextField.text ?? ""
    let email = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if email.isEmpty {
      mailCheckIcon.isHidden = true
      mailCheckLabel.text = " "
      return
    }

    mailCheckIcon.isHidden = false
    mailCheckIcon.image = (isValid ? UIImage.accept : UIImage.reject).withRenderingMode(.alwaysOriginal)
    mailCheckLabel.text = isValid ? "사용 가능한 이메일입니다" : "사용 불가한 이메일입니다"
    mailCheckLabel.textColor = isValid ? .systemSafe : .systemDanger
  }

  func showPasswordValidity(isValid: Bool) {
    let raw = pwTextField.text ?? ""
    let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty {
      pwCheckIcon.isHidden = true
      pwCheckLabel.text = " "
      return
    }

    pwCheckIcon.isHidden = false
    pwCheckIcon.image = (isValid ? UIImage.accept : UIImage.reject).withRenderingMode(.alwaysOriginal)
    pwCheckLabel.text = isValid ? "사용 가능한 비밀번호입니다" : "사용 불가한 비밀번호입니다"
    pwCheckLabel.textColor = isValid ? .systemSafe : .systemDanger
  }

  func showConfirmMatch(isMatched: Bool) {
    // If the confirm field is empty, don't perform or reflect match validation
    let raw = rePwTextField.text ?? ""
    let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty {
      rePwCheckIcon.isHidden = true
      rePwCheckLabel.text = " "
      return
    }

    rePwCheckIcon.isHidden = false
    rePwCheckIcon.image = (isMatched ? UIImage.accept : UIImage.reject).withRenderingMode(.alwaysOriginal)
    rePwCheckLabel.text = isMatched ? "비밀번호가 일치합니다" : "비밀번호가 일치하지 않습니다"
    rePwCheckLabel.textColor = isMatched ? .systemSafe : .systemDanger
  }

  func showNicknameValidity(isValid: Bool) {
    let raw = nicknameTextField.text ?? ""
    let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty {
      nicknameCheckIcon.isHidden = true
      nicknameCheckLabel.text = " "
      return
    }

    nicknameCheckIcon.isHidden = false
    nicknameCheckIcon.image = (isValid ? UIImage.accept : UIImage.reject).withRenderingMode(.alwaysOriginal)
    nicknameCheckLabel.text = isValid ? "사용 가능한 닉네임입니다" : "사용 불가한 닉네임입니다"
    nicknameCheckLabel.textColor = isValid ? .systemSafe : .systemDanger
  }

  func setNextEnabled(_ enabled: Bool) {
    nextButton.isEnabled = enabled
    nextButton.alpha = enabled ? 1.0 : 0.5
  }

  // MARK: - Mail Status Helpers
  private func setMailStatus(text: String, icon: UIImage, color: UIColor) {
    mailCheckIcon.isHidden = false
    mailCheckIcon.image = icon.withRenderingMode(.alwaysOriginal)
    mailCheckLabel.text = text
    mailCheckLabel.textColor = color
  }

  private func isValidEmailRegex(_ email: String) -> Bool {
    let pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
    let predicate = NSPredicate(format: "SELF MATCHES[c] %@", pattern)
    return predicate.evaluate(with: email)
  }

  private var mailCheckTask: Task<Void, Never>?
  private var mailCheckGeneration: Int = 0
  private var isCheckingEmail: Bool = false

  private var isKeyboardObserving = false

  // MARK: - Init
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .white
    headerUI()
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    if window != nil {
      registerKeyboardNotificationsIfNeeded()
    } else {
      unregisterKeyboardNotifications()
    }
  }

  deinit {
    unregisterKeyboardNotifications()
  }

  // MARK: - Header UI
  private func headerUI() {
    addSubview(headerView)
    [backButton, headerLabel].forEach { headerView.addSubview($0) }

    headerView.snp.makeConstraints {
      $0.top.equalTo(safeAreaLayoutGuide.snp.top)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(58)
    }

    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(20)
      $0.centerY.equalTo(headerView.snp.centerY)
    }

    headerLabel.snp.makeConstraints {
      $0.centerX.equalTo(headerView.snp.centerX)
      $0.centerY.equalTo(headerView.snp.centerY)
      $0.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(20)
    }
    otherUI()
    wireActions()
  }

  private func otherUI() {
    [descriptionTitleLabel, scrollView].forEach { addSubview($0) }
    scrollView.addSubview(contentView)

    [mailCheckIcon, mailCheckLabel].forEach { mailCheckStack.addArrangedSubview($0) }
    [pwCheckIcon, pwCheckLabel].forEach { pwCheckStack.addArrangedSubview($0) }
    [rePwCheckIcon, rePwCheckLabel].forEach { rePwCheckStack.addArrangedSubview($0) }
    [nicknameCheckIcon, nicknameCheckLabel].forEach { nicknameCheckStack.addArrangedSubview($0) }

    mailCheckLabel.text = " "
    pwCheckLabel.text = " "
    rePwCheckLabel.text = " "
    nicknameCheckLabel.text = " "

    mailCheckIcon.isHidden = true
    pwCheckIcon.isHidden = true
    rePwCheckIcon.isHidden = true
    nicknameCheckIcon.isHidden = true

    [mailLabel, mailTextField, mailCheckStack].forEach { mailStack.addArrangedSubview($0) }
    [pwLabel, pwTextField, pwCheckStack].forEach { pwStack.addArrangedSubview($0) }
    [rePwLabel, rePwTextField, rePwCheckStack].forEach { rePwStack.addArrangedSubview($0) }
    [nicknameLabel, nicknameTextField, nicknameCheckStack].forEach { nicknameStack.addArrangedSubview($0) }

    [mailStack, pwStack, rePwStack, nicknameStack, nextButton].forEach { contentView.addSubview($0) }

    [mailTextField, pwTextField, rePwTextField, nicknameTextField].forEach {
      $0.snp.makeConstraints { $0.height.equalTo(52) }
    }

    descriptionTitleLabel.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    scrollView.snp.makeConstraints {
      $0.top.equalTo(descriptionTitleLabel.snp.bottom)
      $0.leading.trailing.equalToSuperview()
      $0.bottom.equalTo(safeAreaLayoutGuide)
    }

    contentView.snp.makeConstraints {
      $0.edges.equalTo(scrollView.contentLayoutGuide)
      $0.width.equalTo(scrollView.frameLayoutGuide)
      $0.height.greaterThanOrEqualTo(scrollView.frameLayoutGuide)
    }

    mailStack.snp.makeConstraints {
      $0.top.equalTo(contentView.snp.top).offset(32)
      $0.leading.trailing.equalTo(contentView).inset(20)
    }

    pwStack.snp.makeConstraints {
      $0.top.equalTo(mailStack.snp.bottom).offset(24)
      $0.leading.trailing.equalTo(contentView).inset(20)
    }

    rePwStack.snp.makeConstraints {
      $0.top.equalTo(pwStack.snp.bottom).offset(24)
      $0.leading.trailing.equalTo(contentView).inset(20)
    }

    nicknameStack.snp.makeConstraints {
      $0.top.equalTo(rePwStack.snp.bottom).offset(24)
      $0.leading.trailing.equalTo(contentView).inset(20)
    }

    nextButton.snp.makeConstraints {
      $0.top.greaterThanOrEqualTo(nicknameStack.snp.bottom).offset(24)
      $0.leading.trailing.equalTo(contentView).inset(20)
      $0.height.equalTo(52)
      $0.bottom.equalTo(contentView.safeAreaLayoutGuide).inset(24)
    }

    nextButton.alpha = 0.5
  }

  private func registerKeyboardNotificationsIfNeeded() {
    guard !isKeyboardObserving else { return }
    isKeyboardObserving = true

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleKeyboardWillChangeFrame(_:)),
      name: UIResponder.keyboardWillChangeFrameNotification,
      object: nil
    )
  }

  private func unregisterKeyboardNotifications() {
    guard isKeyboardObserving else { return }
    isKeyboardObserving = false

    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    resetScrollInsets()
  }

  @objc private func handleKeyboardWillChangeFrame(_ notification: Notification) {
    guard
      let userInfo = notification.userInfo,
      let endFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
      let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber,
      let curveNumber = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
    else { return }

    let endFrame = endFrameValue.cgRectValue
    let endFrameInView = convert(endFrame, from: window)
    let intersection = bounds.intersection(endFrameInView)
    let bottomInset = max(0, intersection.height - safeAreaInsets.bottom)

    let options = UIView.AnimationOptions(rawValue: UInt(curveNumber.intValue << 16))

    UIView.animate(
      withDuration: duration.doubleValue,
      delay: 0,
      options: options,
      animations: { [weak self] in
        guard let self = self else { return }
        self.scrollView.contentInset.bottom = bottomInset
        var indicatorInsets = self.scrollView.verticalScrollIndicatorInsets
        indicatorInsets.bottom = bottomInset
        self.scrollView.verticalScrollIndicatorInsets = indicatorInsets

        if bottomInset > 0, let responder = self.findFirstResponder() {
          let responderFrame = responder.convert(responder.bounds, to: self.scrollView)
          self.scrollView.scrollRectToVisible(responderFrame.insetBy(dx: 0, dy: -16), animated: false)
        }
      },
      completion: nil
    )
  }

  private func resetScrollInsets() {
    scrollView.contentInset.bottom = 0
    var indicatorInsets = scrollView.verticalScrollIndicatorInsets
    indicatorInsets.bottom = 0
    scrollView.verticalScrollIndicatorInsets = indicatorInsets
  }

  private func findFirstResponder() -> UIView? {
    if isFirstResponder { return self }
    for sub in subviews {
      if let responder = sub._findFirstResponderRecursively() { return responder }
    }
    return nil
  }

  private func wireActions() {
    mailTextField.addTarget(self, action: #selector(mailEditingDidEnd), for: .editingDidEnd)
    let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tap.cancelsTouchesInView = false
    contentView.addGestureRecognizer(tap)
  }

  @objc private func mailEditingDidEnd() {
    let raw = mailTextField.text ?? ""
    let email = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    if email.isEmpty {
      mailCheckTask?.cancel()
      mailCheckGeneration &+= 1
      isCheckingEmail = false
      mailCheckIcon.isHidden = true
      mailCheckLabel.text = " "
      return
    }

    mailCheckGeneration &+= 1
    let currentGen = mailCheckGeneration
    mailCheckTask?.cancel()

    isCheckingEmail = true

    setMailStatus(text: "이메일 확인 중...", icon: .loading, color: .systemWarning)

    mailCheckTask = Task { [weak self] in
      guard let self = self else { return }
      do {
        let result = try await EmailAvailabilityChecker.check(email: email)

        let statusLowercased = result.status?.lowercased() ?? ""

        guard !Task.isCancelled, currentGen == self.mailCheckGeneration else { return }

        if result.exists {
          if statusLowercased == "waiting" {
            await MainActor.run {
              self.isCheckingEmail = false
              self.setMailStatus(text: "사용할 수 있는 이메일입니다", icon: .accept, color: .systemSafe)
            }
          } else {
            await MainActor.run {
              self.isCheckingEmail = false
              self.setMailStatus(text: "이미 가입된 이메일입니다", icon: .reject, color: .systemDanger)
            }
          }
        } else {
          let isRegexValid = self.isValidEmailRegex(email)

          guard !Task.isCancelled, currentGen == self.mailCheckGeneration else { return }

          await MainActor.run {
            self.isCheckingEmail = false
            if isRegexValid {
              self.setMailStatus(text: "사용할 수 있는 이메일입니다", icon: .accept, color: .systemSafe)
            } else {
              self.setMailStatus(text: "사용할 수 없는 이메일입니다", icon: .reject, color: .systemDanger)
            }
          }
        }
      } catch {
        guard !Task.isCancelled, currentGen == self.mailCheckGeneration else { return }
        await MainActor.run { [weak self] in
          self?.isCheckingEmail = false
          self?.setMailStatus(text: "이메일 확인 실패", icon: .reject, color: .systemDanger)
        }
        print("[Signup][MailCheck] check failed: \(error) email=\(email)")
      }
    }
  }

  @objc private func dismissKeyboard() {
    endEditing(true)
  }
}

extension UIView {
  fileprivate func _findFirstResponderRecursively() -> UIView? {
    if isFirstResponder { return self }
    for sub in subviews {
      if let responder = sub._findFirstResponderRecursively() { return responder }
    }
    return nil
  }
}

class InsetTextField: UITextField {
  var textInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

  override func textRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: textInsets)
  }

  override func editingRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: textInsets)
  }

  override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: textInsets)
  }
}

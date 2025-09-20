//
//  SignupMailConfirmViewController.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import UIKit

import Dependencies
import ReactorKit
import RxCocoa
import RxSwift

// 이메일 가입 3단계
// 가입자에게 보낸 인증 코드를 입력 받고 확인 절차를 거침(가입 완료)

final class SignupMailConfirmViewController: UIViewController, View {
  private var resendCooldownTimer: Timer?
  private var cooldownEndDate: Date?
  private let cooldownDuration: TimeInterval = 40
  private weak var currentPopup: ConfirmPopupView?

  private var codeExpiryTimer: Timer?
  private var codeExpiryEndDate: Date?
  private let codeExpiryDuration: TimeInterval = 180
  private let codeTimerLabel: UILabel = {
    let label = UILabel()
    label.text = "02:59"
    label.textColor = .secondaryLabel
    label.font = .systemFont(ofSize: 14, weight: .regular)
    label.textAlignment = .right
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  var disposeBag = DisposeBag()
  private let rootView = SignupMailConfirmView()
  @Dependency(\.supabase) private var supabase

  override func loadView() {
    self.view = rootView
  }

  init(reactor: SignupMailConfirmReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if cooldownEndDate == nil {
      startCooldown()
    } else {
      ensureCooldownTimerRunningIfNeeded()
    }

    if codeExpiryEndDate == nil {
      startCodeExpiryTimer()
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: false)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    resendCooldownTimer?.invalidate()
    resendCooldownTimer = nil
    codeExpiryTimer?.invalidate()
    codeExpiryTimer = nil
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)

    rootView.attachCodeTimerLabel(codeTimerLabel)
  }

  func bind(reactor: SignupMailConfirmReactor) {
    rootView.helpButton.rx.tap
      .bind(with: self) { owner, _ in
        let popup = ConfirmPopupView(
          title: "인증 메일을 찾을 수 없나요?",
          message: "인증 메일을 찾을 수 없다면 사용 중인 메일 서비스의 스팸함을 확인해 보세요. 확인 후 메일이 오지 않았다면 재전송을 눌러 주세요",
          leftTitle: "재전송",
          rightTitle: "닫기"
        )

        popup.onLeftTap = { [weak owner, weak popup] in
          guard let owner = owner else { return }
          guard let email = KeychainMailStore.load(), !email.isEmpty else {
            DispatchQueue.main.async {
              owner.updateCodeValidation(success: false, message: "이메일 정보를 불러올 수 없어요")
            }
            return
          }
          owner.startCooldown()
          popup?.dismiss()
          owner.startCodeExpiryTimer(reset: true)

          Task {
            do {
              try await owner.supabase.auth.signInWithOTP(email: email, shouldCreateUser: true)
              await MainActor.run {
                owner.rootView.codeCheckLabel.text = "인증 메일을 재전송했어요"
                owner.rootView.codeCheckLabel.textColor = .systemSafe
                owner.rootView.codeCheckIcon.image = .accept
                owner.rootView.codeCheckIcon.tintColor = .systemSafe
              }
            } catch {
              print("[Signup][MailConfirm] 재전송 실패: \(error.localizedDescription)")
            }
          }
        }

        popup.onRightTap = { [weak owner, weak popup] in
          owner?.currentPopup = nil
          popup?.dismiss()
        }

        owner.currentPopup = popup
        popup.show(in: owner.view)

        let remain = owner.remainingCooldownSeconds()
        popup.setLeftButtonTitle(remain > 0 ? "재전송(\(remain)초)" : "재전송")
        popup.setLeftButtonEnabled(remain == 0)
        owner.ensureCooldownTimerRunningIfNeeded()
      }
      .disposed(by: disposeBag)

    rootView.resendTap
      .bind(with: self) { owner, _ in
        guard let email = KeychainMailStore.load(), !email.isEmpty else {
          owner.updateCodeValidation(success: false, message: "이메일 정보를 불러올 수 없어요")
          return
        }

        owner.startCooldown()
        owner.updatePopupCooldownUI()
        owner.startCodeExpiryTimer(reset: true)

        Task {
          do {
            try await owner.supabase.auth.signInWithOTP(email: email, shouldCreateUser: true)
            await MainActor.run {
              owner.rootView.codeCheckLabel.text = "인증 메일을 재전송했어요"
              owner.rootView.codeCheckLabel.textColor = .systemSafe
              owner.rootView.codeCheckIcon.image = .accept
              owner.rootView.codeCheckIcon.tintColor = .systemSafe
            }
          } catch {
            print("[Signup][MailConfirm] 재전송 실패: \(error.localizedDescription)")
          }
        }
      }
      .disposed(by: disposeBag)

    rootView.nextButton.rx.tap
      .bind(with: self) { owner, _ in
        let code = owner.rootView.codeTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard code.count == 6 else { return }
        guard let email = KeychainMailStore.load(), !email.isEmpty else {
          owner.updateCodeValidation(success: false, message: "이메일 정보를 불러올 수 없어요")
          return
        }

        owner.setLoadingState()
        owner.view.isUserInteractionEnabled = false
        owner.rootView.nextButton.alpha = 0.5

        Task {
          defer {
            DispatchQueue.main.async {
              owner.view.isUserInteractionEnabled = true
              let isComplete = (owner.rootView.codeTextField.text?.count ?? 0) == 6
              owner.rootView.nextButton.alpha = isComplete ? 1.0 : 0.5
            }
          }

          do {
            try await owner.supabase.auth.verifyOTP(email: email, token: code, type: .email)

            await MainActor.run { [weak owner] in
              owner?.invalidateCodeExpiryTimer()
            }

            let session = try await owner.supabase.auth.session
            let userId = session.user.id.uuidString
            UserDefaults.standard.set(userId, forKey: LocalStorageCase.nowUser.rawValue)

            let pendingPassword: String? = KeychainHelper.get(forKey: "pendingPassword")
            let pendingNickname: String = UserDefaults.standard.string(forKey: "pending.nickname") ?? ""

            if let pwd = pendingPassword, !pwd.isEmpty {
              try await owner.supabase.auth.update(user: .init(password: pwd))
            }
            if !pendingNickname.isEmpty {
              try await owner.supabase.auth.update(user: .init(data: ["nickname": .string(pendingNickname)]))
            }

            print("[Signup] 가입 완료 - email: \(email), nickname: \(pendingNickname)")

            Task.detached(priority: .background) { [supabase = owner.supabase] in
              do {
                let user = User(
                  id: userId,
                  nickname: pendingNickname,
                  profile: nil,
                  provider: "mail",
                  signDate: Date(),
                  latestUploaded: nil,
                  refreshToken: nil
                )
                _ = try await supabase.from("User_Info").insert(user).execute()
              } catch {
                print("Post-signup background work failed: \(error)")
              }
            }

            KeychainMailStore.clear()
            KeychainHelper.remove(forKey: "pendingPassword")
            UserDefaults.standard.removeObject(forKey: "pending.nickname")

            await MainActor.run {
              reactor.action.onNext(.tapNext)
            }
          } catch {
            await MainActor.run {
              owner.setFailureState()
            }
          }
        }
      }
      .disposed(by: disposeBag)

    rootView.backButton.rx.tap
      .map { .tapBack }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    rootView.codeTextField.rx.controlEvent(.editingDidEndOnExit)
      .bind(with: self) { owner, _ in
        owner.rootView.codeTextField.resignFirstResponder()
      }
      .disposed(by: disposeBag)
  }

  private func setLoadingState() {
    rootView.codeCheckLabel.text = "인증번호 확인 중..."
    rootView.codeCheckLabel.textColor = .systemWarning
    rootView.codeCheckIcon.image = .loading
    rootView.codeCheckIcon.tintColor = .systemWarning
  }

  private func setFailureState() {
    rootView.codeCheckLabel.text = "인증번호가 틀렸습니다"
    rootView.codeCheckLabel.textColor = .systemDanger
    rootView.codeCheckIcon.image = .reject
    rootView.codeCheckIcon.tintColor = .systemDanger
    rootView.codeTextField.layer.borderColor = UIColor.systemDanger.cgColor
  }

  private func remainingCooldownSeconds(now: Date = Date()) -> Int {
    guard let end = cooldownEndDate else { return 0 }
    let remain = Int(ceil(end.timeIntervalSince(now)))
    return max(0, remain)
  }

  private func updatePopupCooldownUI() {
    let remain = remainingCooldownSeconds()
    if let popup = currentPopup {
      popup.setLeftButtonTitle(remain > 0 ? "재전송(\(remain)초)" : "재전송")
      popup.setLeftButtonEnabled(remain == 0)
    }
  }

  private func startCooldown() {
    cooldownEndDate = Date().addingTimeInterval(cooldownDuration)
    updatePopupCooldownUI()
    resendCooldownTimer?.invalidate()
    resendCooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      guard let self else { return }
      let remain = self.remainingCooldownSeconds()
      if let popup = self.currentPopup {
        popup.setLeftButtonTitle(remain > 0 ? "재전송(\(remain)초)" : "재전송")
        popup.setLeftButtonEnabled(remain == 0)
      }
      if remain == 0 {
        self.resendCooldownTimer?.invalidate()
        self.resendCooldownTimer = nil
      }
    }
  }

  private func ensureCooldownTimerRunningIfNeeded() {
    let remain = remainingCooldownSeconds()
    if remain > 0, resendCooldownTimer == nil {
      updatePopupCooldownUI()
      resendCooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
        guard let self else { return }
        let remain = self.remainingCooldownSeconds()
        if let popup = self.currentPopup {
          popup.setLeftButtonTitle(remain > 0 ? "재전송(\(remain)초)" : "재전송")
          popup.setLeftButtonEnabled(remain == 0)
        }
        if remain == 0 {
          self.resendCooldownTimer?.invalidate()
          self.resendCooldownTimer = nil
        }
      }
    }
  }

  private func remainingExpirySeconds(now: Date = Date()) -> Int {
    guard let end = codeExpiryEndDate else { return 0 }
    let remain = Int(ceil(end.timeIntervalSince(now)))
    return max(0, remain)
  }

  private func startCodeExpiryTimer(reset: Bool = false) {
    if reset || codeExpiryEndDate == nil {
      codeExpiryEndDate = Date().addingTimeInterval(codeExpiryDuration)
    }
    codeExpiryTimer?.invalidate()
    updateCodeTimerLabel()
    codeExpiryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      guard let self else { return }
      self.updateCodeTimerLabel()
    }
  }

  private func invalidateCodeExpiryTimer() {
    codeExpiryTimer?.invalidate()
    codeExpiryTimer = nil
  }

  private func updateCodeTimerLabel() {
    let remain = remainingExpirySeconds()
    if remain <= 0 {
      codeTimerLabel.text = "00:00"
      codeTimerLabel.textColor = .systemDanger
      invalidateCodeExpiryTimer()
      return
    }
    let minutes = remain / 60
    let seconds = remain % 60
    codeTimerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    if remain <= 30 {
      codeTimerLabel.textColor = .systemWarning
    } else {
      codeTimerLabel.textColor = .secondaryLabel
    }
  }

  private func updateCodeValidation(success: Bool, message: String) {
    rootView.codeCheckLabel.text = message
    rootView.codeCheckLabel.textColor = success ? .systemSafe : .systemDanger
    rootView.codeTextField.layer.borderColor = (success ? UIColor.systemSafe : UIColor.systemDanger).cgColor
  }
  @objc private func dismissKeyboard() {
    view.endEditing(true)
  }
}


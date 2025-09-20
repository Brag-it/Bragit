//
//  SignupMailConfirmView.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import UIKit

import Dependencies
import RxSwift
import SnapKit
import Then

final class SignupMailConfirmView: UIView, UITextFieldDelegate {
  private let disposeBag = DisposeBag()

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

  private let codeContainer = UIView().then {
    $0.layer.borderColor = UIColor.grayScale100.cgColor
    $0.layer.borderWidth = 1
    $0.layer.cornerRadius = 14
    $0.backgroundColor = .white
  }

  private var timerDigitLabels: [UILabel] = []
  private var timerStackView: UIStackView?

  private var timerColonLabel: UILabel?
  private var timerNormalColor: UIColor = .grayScale700
  private var timerWarningColor: UIColor = .systemWarning
  private var timerDangerColor: UIColor = .systemDanger
  private var warningThresholdSeconds: Int = 60
  private var dangerThresholdSeconds: Int = 30

  private var timerMirror: Timer?
  private var lastTimerText: String?

  private let descriptionTitleLabel = UILabel().then {
    $0.text = "입력한 메일 주소로 인증 코드를 보냈어요"
    $0.numberOfLines = 2
    $0.lineBreakMode = .byWordWrapping
    $0.setContentHuggingPriority(.required, for: .vertical)
    $0.setContentCompressionResistancePriority(.required, for: .vertical)
    $0.font = .pretendard(size: 20, weight: .semibold)
    $0.textColor = .grayScale900
  }

  let descriptionLabel = UILabel().then {
    $0.text = "인증 코드를 아래에 입력해 주세요"
    $0.numberOfLines = 1
    $0.lineBreakMode = .byWordWrapping
    $0.setContentHuggingPriority(.required, for: .vertical)
    $0.setContentCompressionResistancePriority(.required, for: .vertical)
    $0.font = .pretendard(size: 16, weight: .regular)
    $0.textColor = .grayScale700
  }

  let codeTextField = UITextField().then {
    $0.layer.borderColor = UIColor.clear.cgColor
    $0.layer.borderWidth = 0
    $0.layer.cornerRadius = 0
    $0.backgroundColor = .clear
    $0.textAlignment = .center
    $0.isEnabled = true
    $0.returnKeyType = .done
    $0.placeholder = "000000"
    $0.clearButtonMode = .never
    $0.font = .pretendard(size: 28, weight: .semibold)
    $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
    $0.textColor = .grayScale900
    $0.keyboardType = .numberPad
    $0.autocapitalizationType = .none
    $0.spellCheckingType = .no
    $0.autocorrectionType = .no
    $0.isSecureTextEntry = false
    $0.textContentType = .oneTimeCode
  }

  let codeCheckIcon = UIImageView().then {
    $0.contentMode = .scaleAspectFit
    $0.snp.makeConstraints { $0.size.equalTo(16) }
  }

  let codeCheckLabel = UILabel().then {
    $0.text = " "
    $0.font = .pretendard(size: 13, weight: .medium)
    $0.textColor = .systemSafe
  }

  let codeCheckStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 4
    $0.alignment = .leading
  }

  let helpButton = UIButton(type: .system).then {
    $0.setTitle("메일이 오지 않았나요?", for: .normal)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 14, weight: .regular)
    $0.isHidden = false
  }

  let nextButton = UIButton(type: .system).then {
    $0.setTitle("다음", for: .normal)
    $0.setTitleColor(.grayScale900, for: .normal)
    $0.titleLabel?.font = .pretendard(size: 16, weight: .medium)
    $0.layer.cornerRadius = 12
    $0.isEnabled = false
    $0.alpha = 0.5
    $0.backgroundColor = .primary400
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .white
    headerUI()
    codeTextField.delegate = self
    codeTextField.addTarget(self, action: #selector(codeEditingChanged), for: .editingChanged)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

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

    configureUI()
  }

  private func configureUI() {
    [codeCheckIcon, codeCheckLabel].forEach { codeCheckStack.addArrangedSubview($0) }
    [descriptionTitleLabel, descriptionLabel, codeContainer, codeCheckStack, helpButton, nextButton].forEach {
      addSubview($0)
    }

    descriptionTitleLabel.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    descriptionLabel.snp.makeConstraints {
      $0.top.equalTo(descriptionTitleLabel.snp.bottom).offset(8)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    codeContainer.snp.makeConstraints {
      $0.top.equalTo(descriptionLabel.snp.bottom).offset(40)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(64)
    }

    codeContainer.addSubview(codeTextField)
    codeTextField.snp.makeConstraints {
      $0.leading.equalToSuperview().inset(20)
      $0.centerY.equalToSuperview()
    }

    codeCheckStack.snp.makeConstraints {
      $0.top.equalTo(codeContainer.snp.bottom).offset(8)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    helpButton.snp.makeConstraints {
      $0.top.equalTo(codeCheckStack.snp.bottom).offset(18)
      $0.leading.equalToSuperview().inset(20)
    }

    nextButton.snp.makeConstraints {
      $0.bottom.equalTo(safeAreaLayoutGuide).inset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }
  }

  public func attachCodeTimerLabel(_ label: UILabel) {
    let timerFont = UIFont.pretendard(size: 13, weight: .medium)
    self.timerNormalColor = label.textColor ?? .grayScale700

    codeContainer.addSubview(label)
    label.font = timerFont
    label.isHidden = true
    label.snp.makeConstraints {
      $0.trailing.equalToSuperview().inset(20)
      $0.centerY.equalToSuperview()
    }

    let stack = UIStackView()
    stack.axis = .horizontal
    stack.alignment = .center
    stack.spacing = 0
    codeContainer.addSubview(stack)
    self.timerStackView = stack

    let digitSample = "8" as NSString
    let digitWidth = ceil(digitSample.size(withAttributes: [.font: timerFont]).width)

    func makeDigitLabel() -> UILabel {
      let label = UILabel()
      label.font = timerFont
      label.textColor = self.timerNormalColor
      label.textAlignment = .center
      label.text = "0"
      label.setContentHuggingPriority(.required, for: .horizontal)
      label.setContentCompressionResistancePriority(.required, for: .horizontal)
      label.snp.makeConstraints { make in
        make.width.equalTo(digitWidth)
      }
      return label
    }

    let min10 = makeDigitLabel()
    let min1 = makeDigitLabel()
    let colon = UILabel()
    colon.font = timerFont
    colon.textColor = self.timerNormalColor
    colon.text = ":"
    colon.textAlignment = .center
    self.timerColonLabel = colon
    let sec10 = makeDigitLabel()
    let sec1 = makeDigitLabel()

    [min10, min1, colon, sec10, sec1].forEach { stack.addArrangedSubview($0) }
    self.timerDigitLabels = [min10, min1, sec10, sec1]

    let initial = label.text ?? "02:59"
    self.lastTimerText = initial
    self.setTimerText(initial)
    applyTimerColor(forSeconds: seconds(from: initial))

    self.timerMirror?.invalidate()
    self.timerMirror = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self, weak label] _ in
      guard let self = self, let text = label?.text else { return }
      if text != self.lastTimerText {
        self.lastTimerText = text
        self.setTimerText(text)
      }
    }
    RunLoop.main.add(self.timerMirror!, forMode: .common)

    stack.snp.makeConstraints { make in
      make.trailing.equalToSuperview().inset(20)
      make.centerY.equalToSuperview()
    }

    codeTextField.snp.remakeConstraints { make in
      make.leading.equalToSuperview().inset(20)
      make.trailing.equalTo(stack.snp.leading).offset(-10)
      make.centerY.equalToSuperview()
    }
  }

  public func setTimerText(_ text: String) {
    let digits = text.filter { $0.isNumber }
    guard digits.count >= 4, timerDigitLabels.count == 4 else { return }
    let arr = Array(digits.prefix(4))
    timerDigitLabels[0].text = String(arr[0])
    timerDigitLabels[1].text = String(arr[1])
    timerDigitLabels[2].text = String(arr[2])
    timerDigitLabels[3].text = String(arr[3])
    applyTimerColor(forSeconds: seconds(from: text))
  }

  private func seconds(from text: String) -> Int? {
    let parts = text.split(separator: ":")
    guard parts.count == 2,
      let minute = Int(parts[0]),
      let sec = Int(parts[1]) else { return nil }
    return minute * 60 + sec
  }

  private func applyTimerColor(forSeconds seconds: Int?) {
    let secs = seconds ?? Int.max
    let color: UIColor
    if secs < dangerThresholdSeconds {
      color = timerDangerColor
    } else if secs < warningThresholdSeconds {
      color = timerWarningColor
    } else {
      color = timerNormalColor
    }
    timerDigitLabels.forEach { $0.textColor = color }
    timerColonLabel?.textColor = color
  }

  @objc private func codeEditingChanged() {
    let digits = codeTextField.text?.filter { $0.isNumber } ?? ""
    if digits != codeTextField.text {
      codeTextField.text = String(digits.prefix(6))
    } else if digits.count > 6 {
      codeTextField.text = String(digits.prefix(6))
    }

    let isComplete = (codeTextField.text?.count ?? 0) == 6
    nextButton.isEnabled = isComplete
    nextButton.alpha = isComplete ? 1.0 : 0.5
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }

  public func bindTimerText(_ source: Observable<String>) {
    source
      .observe(on: MainScheduler.instance)
      .subscribe { [weak self] text in
        self?.lastTimerText = text
        self?.setTimerText(text)
      }
      .disposed(by: disposeBag)
  }

  deinit {
    timerMirror?.invalidate()
  }
}

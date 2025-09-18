//
//  SignupMailTermsView.swift
//  Bragit
//
//  Created by luca on 9/17/25.
//

import SnapKit
import Then
import UIKit

final class SignupMailTermsView: UIView {
  // MARK: - State
  private var isServiceAccepted: Bool = false
  private var isPrivacyAccepted: Bool = false
  private var isMarketingAccepted: Bool = false

  private let headerView = UIView()
  private let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale90
  }
  private let headerLabel = UILabel().then {
    $0.text = "회원가입"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
  }

  // MARK: UI 컴포넌트 정의

  private let descriptionTitleLabel = UILabel().then {
    $0.text = "서비스 이용을 위해 약관 동의가 필요해요"
    $0.numberOfLines = 2
    $0.lineBreakMode = .byWordWrapping
    $0.setContentHuggingPriority(.required, for: .vertical)
    $0.setContentCompressionResistancePriority(.required, for: .vertical)
    $0.font = .pretendard(size: 20, weight: .semibold)
    $0.textColor = .grayScale900
  }

  // 전체 동의
  let allAcceptCheckbox = UIButton(type: .system).then {
    $0.setImage(UIImage(systemName: "square.fill"), for: .normal)
    $0.contentHorizontalAlignment = .leading
    $0.tintColor = .primary400
  }

  let allAcceptLabel = UILabel().then {
    $0.text = "전체 동의"
    $0.font = .pretendard(size: 16, weight: .medium)
    $0.textColor = .grayScale700
  }

  let allAcceptStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 8
    $0.alignment = .center
  }

  let divider = UIView().then {
    $0.backgroundColor = UIColor(red: 0.851, green: 0.851, blue: 0.851, alpha: 1)
  }

  // 서비스 이용약관
  let serviceAcceptCheckbox = UIButton(type: .system).then {
    $0.setImage(UIImage(systemName: "square.fill"), for: .normal)
    $0.tintColor = .primary400
  }

  // Label + Forward를 버튼 컨테이너로 구성
  let serviceDetailButton = UIButton(type: .system)

  let serviceAcceptStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 8
    $0.alignment = .center
  }

  // 개인정보 수집
  let privacyAcceptCheckbox = UIButton(type: .system).then {
    $0.setImage(UIImage(systemName: "square.fill"), for: .normal)
    $0.tintColor = .primary400
  }

  let privacyDetailButton = UIButton(type: .system)

  let privacyAcceptStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 8
    $0.alignment = .center
  }

  // 마케팅 정보
  let marketingAcceptCheckbox = UIButton(type: .system).then {
    $0.setImage(UIImage(systemName: "square.fill"), for: .normal)
    $0.tintColor = .orange
  }

  let marketingDetailButton = UIButton(type: .system)

  let marketingAcceptStack = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 8
    $0.alignment = .center
    $0.isHidden = true
  }

  // nextButton
  let nextButton = UIButton(type: .system).then {
    $0.setTitle("확인", for: .normal)
    $0.setTitleColor(UIColor(red: 0.315, green: 0.315, blue: 0.315, alpha: 1), for: .normal)
    $0.layer.cornerRadius = 12
    $0.isEnabled = false
    $0.tintColor = .primary400
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .white
    headerUI()
    applyInitialUI()
    setupActions()
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
    configureDetailButton(serviceDetailButton, title: "서비스 이용 약관 (및 소프트웨어 라이선스) (필수)")
    configureDetailButton(privacyDetailButton, title: "개인정보 수집 및 처리 방침 (필수)")
    configureDetailButton(marketingDetailButton, title: "마케팅 정보 수집 및 수신 (선택)")

    [allAcceptCheckbox, allAcceptLabel].forEach { allAcceptStack.addArrangedSubview($0) }
    [serviceAcceptCheckbox, serviceDetailButton].forEach { serviceAcceptStack.addArrangedSubview($0) }
    [privacyAcceptCheckbox, privacyDetailButton].forEach { privacyAcceptStack.addArrangedSubview($0) }
    [marketingAcceptCheckbox, marketingDetailButton].forEach { marketingAcceptStack.addArrangedSubview($0) }

    [allAcceptCheckbox, serviceAcceptCheckbox, privacyAcceptCheckbox, marketingAcceptCheckbox].forEach {
      $0.snp.makeConstraints { $0.width.height.equalTo(24) }
    }

    [
      descriptionTitleLabel,
      allAcceptStack,
      divider,
      serviceAcceptStack,
      privacyAcceptStack,
      marketingAcceptStack,
      nextButton
    ].forEach { addSubview($0) }

    descriptionTitleLabel.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    allAcceptStack.snp.makeConstraints {
      $0.top.equalTo(descriptionTitleLabel.snp.bottom).offset(32)
      $0.leading.equalToSuperview().offset(20)
      $0.trailing.equalToSuperview().inset(20)
    }

    divider.snp.makeConstraints {
      $0.top.equalTo(allAcceptStack.snp.bottom).offset(16)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(1)
    }

    serviceAcceptStack.snp.makeConstraints {
      $0.top.equalTo(divider.snp.bottom).offset(16)
      $0.leading.equalToSuperview().offset(20)
      $0.trailing.equalToSuperview().inset(20)
    }

    privacyAcceptStack.snp.makeConstraints {
      $0.top.equalTo(serviceAcceptStack.snp.bottom).offset(16)
      $0.leading.equalToSuperview().offset(20)
      $0.trailing.equalToSuperview().inset(20)
    }

    marketingAcceptStack.snp.makeConstraints {
      $0.top.equalTo(privacyAcceptStack.snp.bottom).offset(16)
      $0.leading.equalToSuperview().offset(20)
      $0.trailing.equalToSuperview().inset(20)
    }

    nextButton.snp.makeConstraints {
      $0.bottom.equalTo(safeAreaLayoutGuide).inset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }
  }

  func configureDetailButton(_ button: UIButton, title: String) {
    // button.tintColor = .grayScale700
    button.contentHorizontalAlignment = .fill

    let titleLabel = UILabel().then {
      $0.text = title
      $0.font = .pretendard(size: 16, weight: .regular)
      $0.textColor = .grayScale700
      $0.numberOfLines = 2
      $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
      $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    let arrow = UIImageView(image: .forward).then {
      $0.tintColor = .grayScale700
      $0.contentMode = .scaleAspectFit
      $0.setContentHuggingPriority(.required, for: .horizontal)
      $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    [titleLabel, arrow].forEach { button.addSubview($0) }

    titleLabel.snp.makeConstraints {
      $0.leading.equalTo(button.snp.leading)
      $0.centerY.equalTo(button.snp.centerY)
      $0.trailing.lessThanOrEqualTo(arrow.snp.leading).offset(-8)
    }

    arrow.snp.makeConstraints {
      $0.trailing.equalTo(button.snp.trailing)
      $0.centerY.equalTo(button.snp.centerY)
      $0.width.height.equalTo(16)
    }
  }

  // MARK: - Actions
  private func setupActions() {
    allAcceptCheckbox.addTarget(self, action: #selector(didTapAllAccept), for: .touchUpInside)
    serviceAcceptCheckbox.addTarget(self, action: #selector(didTapService), for: .touchUpInside)
    privacyAcceptCheckbox.addTarget(self, action: #selector(didTapPrivacy), for: .touchUpInside)
    marketingAcceptCheckbox.addTarget(self, action: #selector(didTapMarketing), for: .touchUpInside)
  }

  @objc private func didTapService() {
    isServiceAccepted.toggle()
    setCheckboxImage(serviceAcceptCheckbox, checked: isServiceAccepted)
    refreshAggregateStates()
  }

  @objc private func didTapPrivacy() {
    isPrivacyAccepted.toggle()
    setCheckboxImage(privacyAcceptCheckbox, checked: isPrivacyAccepted)
    refreshAggregateStates()
  }

  @objc private func didTapMarketing() {
    // Ignore marketing if the row is hidden
    if !marketingAcceptStack.isHidden {
      isMarketingAccepted.toggle()
      setCheckboxImage(marketingAcceptCheckbox, checked: isMarketingAccepted)
    }
    refreshAggregateStates()
  }

  @objc private func didTapAllAccept() {
    let includeMarketing = !marketingAcceptStack.isHidden

    // Determine if all required (and optional if visible) are currently ON
    let allOn = includeMarketing ? (isServiceAccepted && isPrivacyAccepted && isMarketingAccepted)
                                 : (isServiceAccepted && isPrivacyAccepted)

    // If currently all ON, turn all OFF; otherwise turn all ON
    let newValue = !allOn

    isServiceAccepted = newValue
    isPrivacyAccepted = newValue
    if includeMarketing { isMarketingAccepted = newValue }

    // Update individual checkbox images
    setCheckboxImage(serviceAcceptCheckbox, checked: isServiceAccepted)
    setCheckboxImage(privacyAcceptCheckbox, checked: isPrivacyAccepted)
    if includeMarketing { setCheckboxImage(marketingAcceptCheckbox, checked: isMarketingAccepted) }

    refreshAggregateStates()
  }

  private func refreshAggregateStates() {
    // Update the All Accept icon based on current states
    updateAllAcceptCheckboxImage(service: isServiceAccepted,
                                 privacy: isPrivacyAccepted,
                                 marketing: isMarketingAccepted)

    // Enable next only when required terms are accepted
    updateNextButtonState(enabled: isServiceAccepted && isPrivacyAccepted)
  }

  func applyInitialUI() {
    setCheckboxImage(allAcceptCheckbox, checked: false)
    setCheckboxImage(serviceAcceptCheckbox, checked: false)
    setCheckboxImage(privacyAcceptCheckbox, checked: false)
    setCheckboxImage(marketingAcceptCheckbox, checked: false)

    [serviceAcceptCheckbox, privacyAcceptCheckbox, marketingAcceptCheckbox].forEach {
      $0.contentHorizontalAlignment = .leading
    }

    isServiceAccepted = false
    isPrivacyAccepted = false
    isMarketingAccepted = false
    refreshAggregateStates()
  }

  func setCheckboxImage(_ button: UIButton, checked: Bool) {
    let name = checked ? "checkmark.square.fill" : "square.fill"
    button.setImage(UIImage(systemName: name), for: .normal)
  }

  func updateAllAcceptCheckboxImage(service: Bool, privacy: Bool, marketing: Bool) {
    let includeMarketing = !marketingAcceptStack.isHidden

    let allOn: Bool
    let allOff: Bool

    if includeMarketing {
      allOn = service && privacy && marketing
      allOff = !service && !privacy && !marketing
    } else {
      allOn = service && privacy
      allOff = !service && !privacy
    }

    let imageName: String = allOn ? "checkmark.square.fill" : (allOff ? "square.fill" : "minus.square.fill")
    allAcceptCheckbox.setImage(UIImage(systemName: imageName), for: .normal)
  }

  func updateNextButtonState(enabled: Bool) {
    nextButton.isEnabled = enabled
    nextButton.backgroundColor = .primary400
    nextButton.alpha = enabled ? 1.0 : 0.5
  }

  // func pushTermsDetail(item: TermsItem) {
  //   let viewController = SettingTermsDetailViewController(item: item)
  //   navigationController?.pushViewController(viewController, animated: true)
  // }
}


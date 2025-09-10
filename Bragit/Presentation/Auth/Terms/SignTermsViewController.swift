//
//  TermsViewController.swift
//  Bragit
//
//  Created by luca on 8/25/25.
//
// 약관 동의를 받는 뷰
import UIKit

import ReactorKit
import RxCocoa
import RxSwift
import SnapKit
import Then

final class SignTermsViewController: UIViewController, View {
  var disposeBag = DisposeBag()

  private let headerView = UIView()
  private let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }
  private let headerLabel = UILabel().then {
    $0.text = "회원가입"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
  }

  private let userInfo: UserRegistrationInfo

  let descFont = UIFont.pretendard(size: 20, weight: .semibold)
  let allLabelFont = UIFont.pretendard(size: 16, weight: .medium)
  let checkboxFont = UIFont.pretendard(size: 16, weight: .regular)

  let descColor = UIColor(named: "grayScale900")
  let labelColor = UIColor(named: "grayScale700")
  let primaryColor = UIColor(named: "primary400")

  var onAgree: ((UserRegistrationInfo) -> Void)?

  // MARK: UI
  let descriptionLabel = UILabel().then {
    $0.text = "서비스 이용을 위해 약관 동의가 필요해요"
    $0.numberOfLines = 1
    $0.lineBreakMode = .byWordWrapping
    $0.setContentHuggingPriority(.required, for: .vertical)
    $0.setContentCompressionResistancePriority(.required, for: .vertical)
  }

  // 전체 동의
  let allAcceptCheckbox = UIButton(type: .system).then {
    $0.setImage(UIImage(systemName: "square.fill"), for: .normal)
    $0.contentHorizontalAlignment = .leading
  }

  let allAcceptLabel = UILabel().then {
    $0.text = "전체 동의"
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
    $0.tintColor = .orange
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
    $0.tintColor = .orange
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
  }

  // MARK: - Initializers
  init(userInfo: UserRegistrationInfo) {
    self.userInfo = userInfo
    super.init(nibName: nil, bundle: nil)
    // 내부에서 Reactor 생성
    self.reactor = SignTermsReactor()
  }

  init(userInfo: UserRegistrationInfo, reactor: SignTermsReactor) {
    self.userInfo = userInfo
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    title = "회원가입"
    setupLayout()
    applyInitialUI()
  }
}

// MARK: - Layout & UI setup
private extension SignTermsViewController {
  func setupLayout() {
    view.addSubview(headerView)
    headerView.addSubview(backButton)
    headerView.addSubview(headerLabel)

      // Font/Color 설정
    descriptionLabel.textColor = descColor
    descriptionLabel.font = descFont
    [allAcceptCheckbox, privacyAcceptCheckbox, serviceAcceptCheckbox, marketingAcceptCheckbox, nextButton].forEach {
      $0.tintColor = primaryColor
    }
    allAcceptLabel.font = allLabelFont
    nextButton.titleLabel?.font = allLabelFont

    configureDetailButton(serviceDetailButton, title: "서비스 이용 약관 (필수)")
    configureDetailButton(privacyDetailButton, title: "개인정보 수집 및 처리 방침 (필수)")
    configureDetailButton(marketingDetailButton, title: "마케팅 정보 수집 및 수신 (선택)")

    // all accept stack
    [allAcceptCheckbox, allAcceptLabel].forEach { allAcceptStack.addArrangedSubview($0) }

    // service accept stack
    [serviceAcceptCheckbox, serviceDetailButton].forEach { serviceAcceptStack.addArrangedSubview($0) }

    // privacy accept stack
    [privacyAcceptCheckbox, privacyDetailButton].forEach { privacyAcceptStack.addArrangedSubview($0) }

    // marketing accept stack
    [marketingAcceptCheckbox, marketingDetailButton].forEach { marketingAcceptStack.addArrangedSubview($0) }

    // add view
    [
      descriptionLabel,
      allAcceptStack,
      divider,
      serviceAcceptStack,
      privacyAcceptStack,
      marketingAcceptStack,
      nextButton
    ].forEach {
      view.addSubview($0)
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

    // 체크박스 크기 고정
    [allAcceptCheckbox, serviceAcceptCheckbox, privacyAcceptCheckbox, marketingAcceptCheckbox].forEach {
      $0.snp.makeConstraints { make in
        make.width.height.equalTo(24)
      }
    }

    // 버튼이 체크박스 옆에서 남은 영역을 채우도록
    [serviceDetailButton, privacyDetailButton, marketingDetailButton].forEach {
      $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
      $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    // snapkit
    descriptionLabel.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom).offset(32)
      $0.leading.trailing.equalToSuperview().inset(20)
    }

    allAcceptStack.snp.makeConstraints {
      $0.top.equalTo(descriptionLabel.snp.bottom).offset(32)
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
      $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.height.equalTo(52)
    }
  }

  func configureDetailButton(_ button: UIButton, title: String) {
    button.tintColor = .grayScale700
    button.contentHorizontalAlignment = .fill

    let titleLabel = UILabel().then {
      $0.text = title
      $0.font = checkboxFont
      $0.textColor = .grayScale700
      $0.numberOfLines = 1
      $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
      $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    let chevron = UIImageView(image: .forward).then {
      $0.tintColor = .grayScale700
      $0.contentMode = .scaleAspectFit
      $0.setContentHuggingPriority(.required, for: .horizontal)
      $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    button.addSubview(titleLabel)
    button.addSubview(chevron)

    titleLabel.snp.makeConstraints {
      $0.leading.equalTo(button.snp.leading)
      $0.centerY.equalTo(button.snp.centerY)
      $0.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-8)
    }

    chevron.snp.makeConstraints {
      $0.trailing.equalTo(button.snp.trailing)
      $0.centerY.equalTo(button.snp.centerY)
      $0.width.height.equalTo(16)
    }
  }

  func applyInitialUI() {
    setCheckboxImage(allAcceptCheckbox, checked: false)
    setCheckboxImage(serviceAcceptCheckbox, checked: false)
    setCheckboxImage(privacyAcceptCheckbox, checked: false)
    setCheckboxImage(marketingAcceptCheckbox, checked: false)

    [serviceAcceptCheckbox, privacyAcceptCheckbox, marketingAcceptCheckbox].forEach {
      $0.contentHorizontalAlignment = .leading
    }
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
    nextButton.backgroundColor = primaryColor
    nextButton.alpha = enabled ? 1.0 : 0.5
  }

  func pushTermsDetail(item: TermsItem) {
    let viewController = SettingTermsDetailViewController(item: item)
    navigationController?.pushViewController(viewController, animated: true)
  }
}

// MARK: - Reactor Binding
extension SignTermsViewController {
  func bind(reactor: SignTermsReactor) {
    // Actions
    backButton.rx.tap
      .map { SignTermsReactor.Action.tapBack }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    allAcceptCheckbox.rx.tap
      .map { SignTermsReactor.Action.tapAll }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    serviceAcceptCheckbox.rx.tap
      .map { SignTermsReactor.Action.tapService }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    privacyAcceptCheckbox.rx.tap
      .map { SignTermsReactor.Action.tapPrivacy }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    marketingAcceptCheckbox.rx.tap
      .map { SignTermsReactor.Action.tapMarketing }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    nextButton.rx.tap
      .map { SignTermsReactor.Action.tapNext }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    serviceDetailButton.rx.tap
      .bind(with: self) { owner, _ in
        let item = TermsItem(name: "서비스 이용 약관", bundleFileName: "Terms_Service")
        owner.pushTermsDetail(item: item)
      }
      .disposed(by: disposeBag)

    privacyDetailButton.rx.tap
      .bind(with: self) { owner, _ in
        let item = TermsItem(name: "개인정보 수집 및 처리 방침", bundleFileName: "Terms_PersonalInfo")
        owner.pushTermsDetail(item: item)
      }
      .disposed(by: disposeBag)

    marketingDetailButton.rx.tap
      .bind(with: self) { owner, _ in
        let item = TermsItem(name: "마케팅 정보 수집 및 수신", bundleFileName: "Terms_Marketing")
        owner.pushTermsDetail(item: item)
      }
      .disposed(by: disposeBag)

    reactor.state.map(\.serviceAccepted)
      .distinctUntilChanged()
      .bind(with: self) { owner, accepted in
        owner.setCheckboxImage(owner.serviceAcceptCheckbox, checked: accepted)
      }
      .disposed(by: disposeBag)

    reactor.state.map(\.privacyAccepted)
      .distinctUntilChanged()
      .bind(with: self) { owner, accepted in
        owner.setCheckboxImage(owner.privacyAcceptCheckbox, checked: accepted)
      }
      .disposed(by: disposeBag)

    reactor.state.map(\.marketingAccepted)
      .distinctUntilChanged()
      .bind(with: self) { owner, accepted in
        owner.setCheckboxImage(owner.marketingAcceptCheckbox, checked: accepted)
      }
      .disposed(by: disposeBag)

    Observable
      .combineLatest(
        reactor.state.map(\.serviceAccepted).distinctUntilChanged(),
        reactor.state.map(\.privacyAccepted).distinctUntilChanged(),
        reactor.state.map(\.marketingAccepted).distinctUntilChanged()
      )
      .bind(with: self) { owner, tuple in
        owner.updateAllAcceptCheckboxImage(service: tuple.0, privacy: tuple.1, marketing: tuple.2)
      }
      .disposed(by: disposeBag)

    // State -> UI: next button enable
    reactor.state.map { $0.serviceAccepted && $0.privacyAccepted }
      .distinctUntilChanged()
      .bind(with: self) { owner, enabled in
        owner.updateNextButtonState(enabled: enabled)
      }
      .disposed(by: disposeBag)

    reactor.state.map(\.proceed)
      .distinctUntilChanged()
      .filter { $0 == true }
      .bind(with: self) { owner, _ in
        owner.onAgree?(owner.userInfo)
      }
      .disposed(by: disposeBag)
  }
}

struct UserRegistrationInfo {
  let mail: String
  let password: String?
  let nickname: String
  let isAppleLogin: Bool
  let refreshToken: String?
}

//
//  CancelAccountViewController.swift
//  Bragit
//
//  Created by seongjun cho on 9/4/25.
//

import UIKit

import SnapKit
import Then
import ReactorKit
import RxSwift
import RxCocoa

final class CancelAccountViewController: UIViewController, View {
  var disposeBag = DisposeBag()
  private let headerView = UIView().then {
    $0.backgroundColor = .white
  }

  private let titleLabel = UILabel().then {
    $0.text = "회원 탈퇴"
    $0.font = .pretendard(size: 18, weight: .medium)
    $0.textColor = .grayScale900
  }

  private let backButton = UIButton().then {
    $0.setImage(.back, for: .normal)
  }

  private let textView = UITextView().then {
    $0.isEditable = false
  }

  private let checkBoxButton = UIButton().then {
    $0.setImage(.checkBox, for: .normal)
    $0.setImage(.checkBoxSeleted, for: .selected)
  }

  private let checkLabel = UILabel().then {
    $0.text = "유의 사항을 모두 확인했으며, 탈퇴에 동의합니다"
    $0.font = .pretendard(size: 15)
    $0.textColor = .grayScale900
    $0.numberOfLines = 1
  }

  private let cancelAccountButton = UIButton().then {
    var config = UIButton.Configuration.filled()
    $0.isEnabled = false

    config.background.cornerRadius = 12
    config.title = "탈퇴하기"
    $0.configuration = config
    $0.configurationUpdateHandler = { button in
      switch button.state {
      case .disabled:
        button.configuration?.baseBackgroundColor = .grayScale100
        button.configuration?.baseForegroundColor = .grayScale400
      default:
        button.configuration?.baseBackgroundColor = .primary400
        button.configuration?.baseForegroundColor = .grayScale900
      }
    }
  }

  init(reactor: CancelAccountReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
  }

  private func setupUI() {
    view.backgroundColor = .white
    view.addSubview(headerView)
    headerView.addSubview(titleLabel)
    headerView.addSubview(backButton)
    view.addSubview(textView)
    view.addSubview(checkLabel)
    view.addSubview(checkBoxButton)
    view.addSubview(cancelAccountButton)

    headerView.snp.makeConstraints {
      $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
      $0.height.equalTo(58)
    }

    titleLabel.snp.makeConstraints {
      $0.centerY.centerX.equalToSuperview()
    }

    backButton.snp.makeConstraints {
      $0.centerY.equalToSuperview()
      $0.leading.equalToSuperview().offset(20)
    }

    textView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom)
      $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
      $0.bottom.equalTo(cancelAccountButton.snp.top).inset(-10)
    }

    cancelAccountButton.snp.makeConstraints {
      $0.bottom.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
      $0.height.equalTo(52)
    }

    checkBoxButton.snp.makeConstraints {
      $0.bottom.equalTo(cancelAccountButton.snp.top).inset(-20)
      $0.leading.equalToSuperview().offset(29)
      $0.width.height.equalTo(24)
    }

    checkLabel.snp.makeConstraints {
      $0.leading.equalTo(checkBoxButton.snp.trailing).offset(8)
      $0.centerY.equalTo(checkBoxButton)
      $0.trailing.equalToSuperview().inset(24)
    }
  }

  // swiftlint:disable line_length
  private func setupText(name: String) {

    let attributedString = NSMutableAttributedString()

    let titleAttribute: [NSAttributedString.Key: Any] = [
      .font: UIFont.pretendard(size: 20, weight: .semibold),
      .foregroundColor: UIColor.black,
      .backgroundColor: UIColor.white,
      .paragraphStyle: NSMutableParagraphStyle().then {
        $0.lineHeightMultiple = 1.17
      }
    ]
    let subtitleAttribute: [NSAttributedString.Key: Any] = [
      .font: UIFont.pretendard(size: 15, weight: .semibold),
      .foregroundColor: UIColor.grayScale900,
      .backgroundColor: UIColor.white,
      .paragraphStyle: NSMutableParagraphStyle().then {
        $0.lineHeightMultiple = 1.17
      }
    ]

    let explainAttribute: [NSAttributedString.Key: Any] = [
      .font: UIFont.pretendard(size: 14),
      .foregroundColor: UIColor.grayScale700,
      .backgroundColor: UIColor.white,
      .paragraphStyle: NSMutableParagraphStyle().then {
        $0.lineHeightMultiple = 1.17
      }
    ]

    attributedString.append(NSAttributedString(string: "\(name)님,\n탈퇴 전에 확인할 것이 있어요\n\n", attributes: titleAttribute))

    attributedString.append(NSAttributedString(string: "서비스 이용 불가\n", attributes: subtitleAttribute))

    attributedString.append(NSAttributedString(string: "탈퇴 즉시 계정 정보가 삭제되며, 서비스 이용이 불가해요\n\n", attributes: explainAttribute))

    attributedString.append(NSAttributedString(string: "계정 정보 영구 삭제\n", attributes: subtitleAttribute))

    attributedString.append(NSAttributedString(string: "팔로워, 팔로잉 등의 계정 정보와 입력한 개인 정보는 영구히 삭제되고, 복구할 수 없어요(단, 관련 법령에 따라 보관이 필요한 경우 해당 기간 동안 정보가 보관되며, 보관 사유가 해제되면 정보 또한 즉시 삭제돼요)\n\n", attributes: explainAttribute))

    attributedString.append(NSAttributedString(string: "활동 내역 보관\n", attributes: subtitleAttribute))

    attributedString.append(NSAttributedString(string: "작성한 게시글 및 댓글을 비롯한 모든 활동 내역은 탈퇴 후에도 삭제되지 않아요\n", attributes: explainAttribute))

    textView.attributedText = attributedString
  }
  // swiftlint:enable line_length

  func bind(reactor: CancelAccountReactor) {
    checkBoxButton.rx.tap
      .map { .checkBoxTap }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    reactor.state.map { $0.isAgree }.bind { [checkBoxButton, cancelAccountButton] isAgree in
      checkBoxButton.isSelected = isAgree
      cancelAccountButton.isEnabled = isAgree
    }
    .disposed(by: disposeBag)

    backButton.rx.tap
      .map { .backButtonTap }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    self.rx.viewDidLoad
      .map { _ in .setUserInform }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    reactor.state.map { $0.user }.bind { user in
      self.setupText(name: user?.nickname ?? "사용자")
    }.disposed(by: disposeBag)
  }
}

@available(iOS 18.0, *)
#Preview {
  CancelAccountViewController(reactor: CancelAccountReactor())
}

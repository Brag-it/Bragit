//
//  Alert.swift
//  Bragit
//
//  Created by 이태윤 on 8/22/25.
//
import UIKit

import RxCocoa
import RxSwift
import SnapKit
import Then

final class AlertView: UIView {

  // MARK: - UI
  private let dimmedView = UIView().then {
    $0.backgroundColor = UIColor.black.withAlphaComponent(0.4)
  }

  private let containerView = UIView().then {
    $0.backgroundColor = .white
    $0.layer.cornerRadius = 14
    $0.clipsToBounds = true
  }

  private let titleLabel = UILabel().then {
    $0.textColor = .black
    $0.font = UIFont.pretendard(size: 16, weight: .semibold)
    $0.textAlignment = .left
    $0.numberOfLines = 0
  }

  private let messageLabel = UILabel().then {
    $0.textColor = .lightGray
    $0.font = UIFont.pretendard(size: 15, weight: .regular)
    $0.textAlignment = .left
    $0.numberOfLines = 0
  }

  private let leftButton = UIButton().then {
    $0.setTitleColor(.black, for: .normal)
    $0.titleLabel?.font = UIFont.pretendard(size: 15, weight: .medium)
  }

  private let rightButton = UIButton().then {
    $0.setTitleColor(.black, for: .normal)
    $0.titleLabel?.font = UIFont.pretendard(size: 15, weight: .medium)
  }

  private let buttonStackView = UIStackView().then {
    $0.axis = .horizontal
    $0.spacing = 0
    $0.distribution = .fillEqually
  }

  // MARK: - Rx Output
  let leftTap = PublishRelay<Void>()
  let rightTap = PublishRelay<Void>()
  private let disposeBag = DisposeBag()

  // MARK: - Init
  init(
    title: String,
    message: String,
    leftButtonTitle: String? = nil,
    rightButtonTitle: String? = nil,
    leftButtonColor: UIColor? = nil,
    rightButtonColor: UIColor? = nil
  ) {
    super.init(frame: UIScreen.main.bounds)
    setUIConstraints()

    titleLabel.text = title
    messageLabel.text = message
    leftButton.setTitle(leftButtonTitle, for: .normal)
    rightButton.setTitle(rightButtonTitle, for: .normal)
    if let leftColor = leftButtonColor {
      leftButton.setTitleColor(leftColor, for: .normal)
    }
    if let rightColor = rightButtonColor {
      rightButton.setTitleColor(rightColor, for: .normal)
    }
    bind()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Layout
  private func setUIConstraints() {
    addSubview(dimmedView)
    addSubview(containerView)

    containerView.addSubview(titleLabel)
    containerView.addSubview(messageLabel)
    containerView.addSubview(buttonStackView)

    buttonStackView.addArrangedSubview(leftButton)
    buttonStackView.addArrangedSubview(rightButton)

    dimmedView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }

    containerView.snp.makeConstraints {
      $0.center.equalToSuperview()
      $0.width.equalTo(280)
    }

    titleLabel.snp.makeConstraints {
      $0.top.equalToSuperview().offset(20)
      $0.leading.trailing.equalToSuperview().inset(24)
    }

    messageLabel.snp.makeConstraints {
      $0.top.equalTo(titleLabel.snp.bottom).offset(16)
      $0.leading.trailing.equalToSuperview().inset(24)
    }

    buttonStackView.snp.makeConstraints {
      $0.top.equalTo(messageLabel.snp.bottom).offset(10)
      $0.leading.trailing.bottom.equalToSuperview()
      $0.height.equalTo(48)
    }
  }

  // MARK: - 바인딩
  private func bind() {
    leftButton.rx.tap
      .bind(with: self) { owner, _ in
        owner.removeFromSuperview()
        owner.leftTap.accept(())
      }
      .disposed(by: disposeBag)

    rightButton.rx.tap
      .bind(with: self) { owner, _ in
        owner.removeFromSuperview()
        owner.rightTap.accept(())
      }
      .disposed(by: disposeBag)
  }

  // MARK: - 화면에 띄우기
  func show(in view: UIView) {
    view.addSubview(self)
  }
}

// MARK: - 스타일
extension AlertView {
  // 원하는 스타일
  enum AlertStyle {
    case tempSaveDraft  //임시저장
    case deletePost  // 게시글 삭제
    case reportPost  // 게시글 신고
    case deleteComment  // 댓글 삭제
    case reportComment  // 댓글 신고
    case blockUser(nickname: String)  // 유저 차단
    case reportUser(nickname: String)  // 유저 신고
    case reportApp  // 앱에 대한 신고
    case logOut  // 로그아웃
    case deleteAcount  // 회원탈퇴
  }

  static func makeAlert(style: AlertStyle) -> AlertView {
    switch style {
    case .tempSaveDraft:
      return AlertView(
        title: "이 페이지를 나갈까요?",
        message: "지금 나가면 저장하지 않은 글은 삭제돼요.",
        leftButtonTitle: "나가기",
        rightButtonTitle: "임시저장",
        leftButtonColor: .gray,
        rightButtonColor: .black
      )
    case .deletePost:
      return AlertView(
        title: "게시글을 삭제할까요?",
        message: "삭제된 게시물은 복구할 수 없어요.",
        leftButtonTitle: "취소",
        rightButtonTitle: "삭제하기",
        leftButtonColor: .gray,
        rightButtonColor: .systemRed
      )
    case .reportPost:
      return AlertView(
        title: "게시글을 신고할까요?",
        message: "신고가 접수된 게시글은 내부 검토를 거쳐 삭제될 수 있어요.",
        leftButtonTitle: "취소",
        rightButtonTitle: "신고하기",
        leftButtonColor: .gray,
        rightButtonColor: .systemRed
      )
    case .deleteComment:
      return AlertView(
        title: "댓글을 삭제할까요?",
        message: "삭제된 댓글은 복구할 수 없어요.",
        leftButtonTitle: "취소",
        rightButtonTitle: "삭제하기",
        leftButtonColor: .gray,
        rightButtonColor: .systemRed
      )
    case .reportComment:
      return AlertView(
        title: "댓글을 신고할까요?",
        message: "신고가 접수된 댓글은 내부 검토를 거쳐 삭제될 수 있어요.",
        leftButtonTitle: "취소",
        rightButtonTitle: "신고하기",
        leftButtonColor: .gray,
        rightButtonColor: .systemRed
      )
    case .blockUser(let nickname):
      return AlertView(
        title: "\(nickname)님을 차단할까요?",
        message: "차단하면 \(nickname)님의 게시글과 댓글, 검색이 되지 않으며, 팔로잉, 팔로워 목록에서 삭제돼요. 차단여부는 상대방이 알수 없어요.",
        leftButtonTitle: "취소",
        rightButtonTitle: "차단하기",
        leftButtonColor: .gray,
        rightButtonColor: .systemRed
      )
    case .reportUser(let nickname):
      return AlertView(
        title: "\(nickname)님을 신고할까요?",
        message: "신고가 접수된 사용자는 내부 검토 후 활동이 정지될 수 있어요.",
        leftButtonTitle: "취소",
        rightButtonTitle: "신고하기",
        leftButtonColor: .gray,
        rightButtonColor: .systemRed
      )
    case .reportApp:
      return AlertView(
        title: "작성한 신고 내용을 제출할 까요?",
        message: "악의적인 비벙이나 허위 사실이 담긴 내용을 고의적으로 제출할 경우 처벌 대상이 될 수 있어요.",
        leftButtonTitle: "취소",
        rightButtonTitle: "제출하기",
        leftButtonColor: .gray,
        rightButtonColor: .black
      )
    case .logOut:
      return AlertView(
        title: "로그아웃할까요?",
        message: "자동 로그인 기능이 해제돼요.",
        leftButtonTitle: "취소",
        rightButtonTitle: "로그아웃",
        leftButtonColor: .gray,
        rightButtonColor: .systemRed
      )
    case .deleteAcount:
      return AlertView(
        title: "정말 탈퇴 하시겠어요..?",
        message: "Bragit을 탈퇴하면, Bargit 아이디를 포함한 모든 이용 기록이 삭제되고 삭제된 정보는 복구되지 않아요.",
        leftButtonTitle: "취소",
        rightButtonTitle: "탈퇴하기",
        leftButtonColor: .gray,
        rightButtonColor: .systemRed
      )
    }
  }
}

//
//  DetailPostViewController.swift
//  Bragit
//
//  Created by 이태윤 on 9/4/25.
//
import UIKit
import PhotosUI

import ReactorKit
import RxSwift
import RxCocoa
import SnapKit
import Then

class DetailPostViewController: UIViewController, View {
  var disposeBag = DisposeBag()
  private let reportAlert = AlertView.makeAlert(style: .reportPost)
  private let deleteAlert = AlertView.makeAlert(style: .deletePost)

  private let headerView = UIView()
  private let bottomView = UIView()

  private let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }

  private let titleLabel = UILabel().then {
    $0.text = "게시물"
    $0.font = UIFont.systemFont(ofSize: 16)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
    $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
  }

  private let kebabButton = UIButton(type: .system).then {
    $0.setImage(.kebab, for: .normal)
    $0.tintColor = .grayScale900
  }

  private let favoriteButton = UIButton(type: .system).then {
    let image = UIImage.favorite.resized(to: CGSize(width: 32, height: 32))
    $0.setImage(image, for: .normal)
    $0.tintColor = .grayScale900
  }

  private let favoriteCount = UILabel().then {
    $0.font = .pretendard(size: 16)
    $0.textColor = .grayScale600
  }

  private let commentButton = UIButton(type: .system).then {
    let image = UIImage.comment.resized(to: CGSize(width: 32, height: 32))
    $0.setImage(image, for: .normal)
    $0.tintColor = .grayScale900
  }

  init(reactor: DetailPostReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    let menu = if reactor?.currentState.viewer == true{
      MenuView(items: ["수정하기", "삭제하기"])
    } else {
      MenuView(items: ["수정하기"])
    }

    setUIConstraints()
    print("제목 : \(String(describing: reactor?.currentState.title))")
    print("내용 : \(String(describing: reactor?.currentState.content))")
    print("닉네임 : \(String(describing: reactor?.currentState.nickName))")
    print("보는사람(작성자인지): \(String(describing: reactor?.currentState.viewer))")
  }

  // UI 설정
  private func setUIConstraints() {

    view.addSubview(headerView)
    headerView.addSubview(backButton)
    headerView.addSubview(titleLabel)
    headerView.addSubview(kebabButton)

    view.addSubview(bottomView)
    bottomView.addSubview(favoriteButton)
    bottomView.addSubview(favoriteCount)
    bottomView.addSubview(commentButton)

    headerView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(58)
    }

    backButton.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(20)
      $0.centerY.equalTo(headerView.snp.centerY)
    }

    titleLabel.snp.makeConstraints {
      $0.centerX.equalTo(headerView.snp.centerX)
      $0.centerY.equalTo(headerView.snp.centerY)
      $0.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(20)
      $0.trailing.lessThanOrEqualTo(kebabButton.snp.leading).offset(-20)
    }

    kebabButton.snp.makeConstraints {
      $0.trailing.equalToSuperview().inset(20)
      $0.centerY.equalTo(headerView.snp.centerY)
    }

    bottomView.snp.makeConstraints {
      $0.bottom.equalTo(view.safeAreaLayoutGuide)
      $0.leading.trailing.equalToSuperview()
      $0.height.equalTo(52)
    }

    favoriteButton.snp.makeConstraints {
      $0.leading.equalToSuperview().offset(20)
      $0.centerY.equalTo(bottomView.snp.centerY)
    }

    favoriteCount.snp.makeConstraints {
      $0.leading.equalTo(favoriteButton.snp.trailing).offset(4)
      $0.centerY.equalTo(bottomView.snp.centerY)
    }

    commentButton.snp.makeConstraints {
      $0.trailing.equalToSuperview().offset(-20)
      $0.centerY.equalTo(bottomView.snp.centerY)
    }
  }

  func bind(reactor: DetailPostReactor) {
    reportAlert.leftTap
      .bind { print("취소 버튼 누름") }
      .disposed(by: disposeBag)

    deleteAlert.leftTap
      .bind { print("취소 버튼 누름") }
      .disposed(by: disposeBag)

    reportAlert.rightTap
      .bind { print("신고 버튼 누름") }
      .disposed(by: disposeBag)

    deleteAlert.rightTap
      .bind { print("삭제 버튼 누름") }
      .disposed(by: disposeBag)

    backButton.rx.tap
      .map { Reactor.Action.didTapBack }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    favoriteButton.rx.tap
      .map { Reactor.Action.didTapLike }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    commentButton.rx.tap
      .map { Reactor.Action.didTapComment }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)
  }
}

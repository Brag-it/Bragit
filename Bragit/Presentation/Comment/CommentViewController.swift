//
//  CommentViewController.swift
//  Bragit
//
//  Created by luca on 9/4/25.
//

import UIKit

import ReactorKit
import RxSwift
import RxCocoa
import SnapKit
import Then
import Kingfisher

final class CommentViewController: UIViewController, View {
  typealias Reactor = CommentReactor
  var disposeBag = DisposeBag()

  // MARK: UI
  private let tableView = UITableView(frame: .zero, style: .plain).then {
    $0.register(CommentCell.self, forCellReuseIdentifier: CommentCell.reuseID)
    $0.rowHeight = UITableView.automaticDimension
    $0.estimatedRowHeight = 100
    $0.tableFooterView = UIView()
    $0.separatorStyle = .none
    $0.backgroundColor = .systemBackground
    $0.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
  }

  private let activityIndicator = UIActivityIndicatorView(style: .medium).then {
    $0.hidesWhenStopped = true
  }

  init(reactor: CommentReactor) {
    super.init(nibName: nil, bundle: nil)
    self.reactor = reactor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "댓글"
    view.backgroundColor = .systemBackground
    setupLayout()

    if let reactor = reactor {
      print("CommentVC with postId: \(reactor.postIdForDebug.uuidString)")
    }
  }

  private func setupLayout() {
    view.addSubview(tableView)
    view.addSubview(activityIndicator)

    tableView.snp.makeConstraints {
      $0.edges.equalTo(view.safeAreaLayoutGuide)
    }
    activityIndicator.snp.makeConstraints {
      $0.center.equalToSuperview()
    }
  }

  func bind(reactor: CommentReactor) {
    // 화면 진입 시 댓글 로드
    rx.viewDidLoad
      .map { Reactor.Action.refresh }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 로딩 인디케이터
    reactor.state
      .map(\.isLoading)
      .distinctUntilChanged()
      .observe(on: MainScheduler.instance)
      .bind(with: self) { owner, loading in
        loading ? owner.activityIndicator.startAnimating() : owner.activityIndicator.stopAnimating()
        owner.view.isUserInteractionEnabled = !loading
      }
      .disposed(by: disposeBag)

    // ViewController에서도 content, date 콘솔 출력
    reactor.state
      .map(\.comments)
      .distinctUntilChanged()
      .bind(with: self) { _, rows in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        rows.forEach { row in
          let dateString = formatter.string(from: row.date)
          print("ViewController with content: \(row.content), date: \(dateString)")
        }
      }
      .disposed(by: disposeBag)

    // 댓글 바인딩 (커스텀 셀)
    reactor.state
      .map(\.comments)
      .bind(to: tableView.rx.items(cellIdentifier: CommentCell.reuseID, cellType: CommentCell.self)) { _, row, cell in
        cell.configure(
          nickname: row.userInfo?.nickname ?? "탈퇴한 유저입니다.",
          profileURLString: row.userInfo?.profile,
          date: row.date,
          content: row.content
        )
      }
      .disposed(by: disposeBag)

    // 에러 표시
    reactor.state
      .compactMap(\.errorMessage)
      .observe(on: MainScheduler.instance)
      .bind(with: self) { owner, message in
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "확인", style: .default))
        owner.present(alert, animated: true)
      }
      .disposed(by: disposeBag)
  }
}

final class CommentCell: UITableViewCell {

  static let reuseID = "CommentCell"

  private let profileImageView = UIImageView().then {
    $0.contentMode = .scaleAspectFill
    $0.clipsToBounds = true
    $0.layer.cornerRadius = 18 // 36x36 원형
    $0.backgroundColor = .secondarySystemBackground
    $0.snp.makeConstraints { $0.size.equalTo(CGSize(width: 36, height: 36)) }
  }

  private let nameLabel = UILabel().then {
    $0.font = .pretendard(size: 15, weight: .medium)
    $0.textColor = .label
    $0.numberOfLines = 1
    $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
  }

  private let dateLabel = UILabel().then {
    $0.font = .pretendard(size: 13)
    $0.textColor = .secondaryLabel
    $0.textAlignment = .right
    $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    $0.setContentHuggingPriority(.required, for: .horizontal)
  }

  private let kebabImageView = UIImageView(image: .kebab).then {
    $0.contentMode = .scaleAspectFit
    $0.tintColor = .tertiaryLabel
    $0.snp.makeConstraints { $0.size.equalTo(CGSize(width: 20, height: 20)) }
    $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    $0.setContentHuggingPriority(.required, for: .horizontal)
  }

  private let contentLabel = UILabel().then {
    $0.font = .pretendard(size: 15)
    $0.textColor = .label
    $0.numberOfLines = 0
  }

  private let headerContainer = UIView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    setupLayout()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupLayout() {
    contentView.addSubview(headerContainer)
    contentView.addSubview(contentLabel)

    headerContainer.addSubview(profileImageView)
    headerContainer.addSubview(nameLabel)
    headerContainer.addSubview(dateLabel)
    headerContainer.addSubview(kebabImageView)

    headerContainer.snp.makeConstraints {
      $0.top.equalToSuperview().offset(12)
      $0.leading.trailing.equalToSuperview().inset(16)
      $0.bottom.equalTo(profileImageView.snp.bottom)
    }

    profileImageView.snp.makeConstraints {
      $0.top.leading.equalToSuperview()
    }

    nameLabel.snp.makeConstraints {
      $0.leading.equalTo(profileImageView.snp.trailing).offset(8)
      $0.centerY.equalTo(profileImageView.snp.centerY)
      $0.trailing.lessThanOrEqualTo(dateLabel.snp.leading).offset(-8)
    }

    kebabImageView.snp.makeConstraints {
      $0.trailing.equalToSuperview()
      $0.centerY.equalTo(profileImageView.snp.centerY)
    }

    dateLabel.snp.makeConstraints {
      $0.trailing.equalTo(kebabImageView.snp.leading).offset(-8)
      $0.centerY.equalTo(profileImageView.snp.centerY)
    }

    contentLabel.snp.makeConstraints {
      $0.top.equalTo(headerContainer.snp.bottom).offset(8)
      $0.leading.trailing.equalToSuperview().inset(16)
      $0.bottom.equalToSuperview().inset(12)
    }
  }

  func configure(nickname: String, profileURLString: String?, date: Date, content: String) {
    nameLabel.text = nickname

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy.MM.dd"
    dateLabel.text = formatter.string(from: date)

    contentLabel.text = content

    if let urlString = profileURLString, let url = URL(string: urlString) {
      profileImageView.kf.setImage(with: url, placeholder: UIImage.profilePerson)
    } else {
      profileImageView.image = UIImage.profilePerson
    }
  }
}

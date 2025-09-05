//
//  CommentViewController.swift
//  Bragit
//
//  Created by luca on 9/4/25.
//

import Kingfisher
import ReactorKit
import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class CommentViewController: UIViewController, View {
  typealias Reactor = CommentReactor
  var disposeBag = DisposeBag()

  // MARK: UI
  private let reportAlert = AlertView.makeAlert(style: .reportComment)
  private let deleteAlert = AlertView.makeAlert(style: .deleteComment)

  private let headerView = UIView()

  private let backButton = UIButton(type: .system).then {
    $0.setImage(.back, for: .normal)
    $0.tintColor = .grayScale900
  }

  private let titleLabel = UILabel().then {
    $0.text = "댓글"
    $0.font = UIFont.systemFont(ofSize: 16)
    $0.textColor = .grayScale900
    $0.textAlignment = .center
    $0.setContentHuggingPriority(.defaultLow, for: .horizontal)
  }

  private let kebabButton = UIButton(type: .system).then {
    $0.setImage(.kebab, for: .normal)
    $0.tintColor = .grayScale900
  }

  private let tableView = UITableView(frame: .zero, style: .plain).then {
    $0.register(CommentCell.self, forCellReuseIdentifier: CommentCell.reuseID)
    $0.rowHeight = UITableView.automaticDimension
    $0.estimatedRowHeight = 100
    $0.tableFooterView = UIView()
    $0.separatorStyle = .none
    $0.backgroundColor = .systemBackground
    $0.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
    $0.keyboardDismissMode = .onDrag
  }

  private let activityIndicator = UIActivityIndicatorView(style: .medium).then {
    $0.hidesWhenStopped = true
  }

  private let commentTextView = UITextView()

  // 화면 빈 곳 탭 시 키보드 내리기용 제스처
  private lazy var dismissTapGesture: UITapGestureRecognizer = {
    let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tap.cancelsTouchesInView = false
    return tap
  }()

  // 액세서리 바
  private lazy var bottomBar: UIView = {
    let bar = UIView()
    bar.backgroundColor = .grayScale50
    bar.snp.makeConstraints { $0.height.equalTo(54) }

    let lockImageView = UIImageView(image: .unlock).then {
      $0.contentMode = .scaleAspectFit
    }

    let textContainer = UIView().then {
      $0.backgroundColor = .white
      $0.layer.cornerRadius = 12
      $0.layer.masksToBounds = true
    }

    let sendImageView = UIImageView(image: .send).then {
      $0.contentMode = .scaleAspectFit
      $0.isUserInteractionEnabled = false
    }

    let tapOverlay = UIButton(type: .custom)
    tapOverlay.backgroundColor = .clear
    tapOverlay.addTarget(self, action: #selector(beginInputFromBottomBar), for: .touchUpInside)

    bar.addSubview(lockImageView)
    bar.addSubview(textContainer)
    bar.addSubview(sendImageView)
    textContainer.addSubview(tapOverlay)

    lockImageView.snp.makeConstraints {
      $0.leading.equalTo(bar.snp.leading).offset(12)
      $0.centerY.equalTo(bar.snp.centerY)
    }

    textContainer.snp.makeConstraints {
      $0.leading.equalTo(lockImageView.snp.trailing).offset(10)
      $0.trailing.equalTo(bar.snp.trailing).inset(12)
      $0.centerY.equalTo(bar.snp.centerY)
      $0.height.equalTo(42)
    }

    sendImageView.snp.makeConstraints {
      $0.trailing.equalTo(textContainer.snp.trailing).inset(12)
      $0.centerY.equalTo(textContainer.snp.centerY)
    }

    tapOverlay.snp.makeConstraints { $0.edges.equalToSuperview() }

    return bar
  }()

  private lazy var accessoryBar: UIView = {
    let bar = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 54))
    bar.backgroundColor = .grayScale50

    let lockImageView = UIImageView(image: .unlock).then {
      $0.contentMode = .scaleAspectFit
    }

    let textContainer = UIView().then {
      $0.backgroundColor = .white
      $0.layer.cornerRadius = 12
      $0.layer.masksToBounds = true
    }

    let sendImageView = UIImageView(image: .send).then {
      $0.contentMode = .scaleAspectFit
      $0.isUserInteractionEnabled = true
    }

    commentTextView.backgroundColor = .clear
    commentTextView.font = .pretendard(size: 15, weight: .regular)
    commentTextView.textColor = .grayScale900
    commentTextView.isScrollEnabled = false

    bar.addSubview(lockImageView)
    bar.addSubview(textContainer)
    bar.addSubview(sendImageView)
    textContainer.addSubview(commentTextView)

    lockImageView.snp.makeConstraints {
      $0.leading.equalTo(bar.snp.leading).offset(12)
      $0.centerY.equalTo(bar.snp.centerY)
    }

    textContainer.snp.makeConstraints {
      $0.leading.equalTo(lockImageView.snp.trailing).offset(10)
      $0.trailing.equalTo(bar.snp.trailing).inset(12)
      $0.centerY.equalTo(bar.snp.centerY)
      $0.height.equalTo(42)
    }

    sendImageView.snp.makeConstraints {
      $0.trailing.equalTo(textContainer.snp.trailing).inset(12)
      $0.centerY.equalTo(textContainer.snp.centerY)
    }

    commentTextView.snp.makeConstraints {
      $0.edges.equalToSuperview()
      $0.height.equalTo(42)
    }

    commentTextView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 34)

    let tap = UITapGestureRecognizer(target: self, action: #selector(didTapSend))
    sendImageView.addGestureRecognizer(tap)

    return bar
  }()

  override var canBecomeFirstResponder: Bool { true }
  override var inputAccessoryView: UIView? { accessoryBar }

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
    view.backgroundColor = .white
    setupLayout()
    setupKeyboardObservation()
    setupDismissKeyboardGesture()
  }

  private func setupLayout() {
    view.addSubview(headerView)
    headerView.addSubview(backButton)
    headerView.addSubview(titleLabel)
    headerView.addSubview(kebabButton)

    view.addSubview(tableView)
    view.addSubview(activityIndicator)
    view.addSubview(bottomBar)

    headerView.snp.makeConstraints {
      $0.top.equalTo(view.safeAreaLayoutGuide)
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

    bottomBar.snp.makeConstraints {
      $0.leading.trailing.equalToSuperview()
      $0.bottom.equalTo(view.keyboardLayoutGuide)
      $0.height.equalTo(54)
    }

    tableView.snp.makeConstraints {
      $0.top.equalTo(headerView.snp.bottom)
      $0.leading.trailing.equalToSuperview()
      $0.bottom.equalTo(bottomBar.snp.top)
    }

    activityIndicator.snp.makeConstraints {
      $0.center.equalToSuperview()
    }
  }

  private func setupKeyboardObservation() {
    NotificationCenter.default
      .addObserver(
        self,
        selector: #selector(keyboardWillShow(_:)),
        name: UIResponder.keyboardWillShowNotification,
        object: nil
      )
    NotificationCenter.default
      .addObserver(
        self,
        selector: #selector(keyboardWillHide(_:)),
        name: UIResponder.keyboardWillHideNotification,
        object: nil
      )
  }

  private func setupDismissKeyboardGesture() {
    // 화면 빈 곳 탭 시 키보드 내리기
    view.addGestureRecognizer(dismissTapGesture)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - Selectors
  @objc private func beginInputFromBottomBar() {
    commentTextView.becomeFirstResponder()
  }

  @objc private func didTapSend() {
    commentTextView.resignFirstResponder()
    // TODO: Send comment action via reactor if needed.
  }

  @objc private func dismissKeyboard() {
    // accessoryView 내부 first responder까지 포함해 편집 종료
    if let window = view.window {
      window.endEditing(true)
    } else {
      view.endEditing(true)
    }
  }

  @objc private func keyboardWillShow(_ note: Notification) {
    bottomBar.isHidden = true
  }

  @objc private func keyboardWillHide(_ note: Notification) {
    bottomBar.isHidden = false
  }

  func bind(reactor: CommentReactor) {
    backButton.rx.tap
      .map { Reactor.Action.didTapBack }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 화면 진입 시 댓글 로드
    rx.viewDidLoad
      .map { Reactor.Action.refresh }
      .bind(to: reactor.action)
      .disposed(by: disposeBag)

    // 댓글 목록 바인딩
    reactor.state
      .map(\.comments)
      .distinctUntilChanged()
      .observe(on: MainScheduler.instance)
      .bind(
        to: tableView.rx.items(
          cellIdentifier: CommentCell.reuseID,
          cellType: CommentCell.self
        )
      ) { index, row, cell in
        let nickname = (row.user?.nickname?.isEmpty == false) ? row.user!.nickname! : "탈퇴한 회원"
        let profile = row.user?.profile
        cell.configure(
          nickname: nickname,
          profileURLString: profile,
          date: row.date,
          content: row.content
        )
      }
      .disposed(by: disposeBag)

    // 로딩 인디케이터
    reactor.state
      .map(\.isLoading)
      .distinctUntilChanged()
      .observe(on: MainScheduler.instance)
      .bind(with: self) { owner, loading in
        if loading {
          owner.activityIndicator.startAnimating()
        } else {
          owner.activityIndicator.stopAnimating()
        }
        owner.view.isUserInteractionEnabled = !loading
      }
      .disposed(by: disposeBag)

    // 에러 표시
    reactor.state
      .compactMap(\.errorMessage)
      .observe(on: MainScheduler.instance)
      .bind(with: self) { owner, message in
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        owner.present(alert, animated: true) {
          alert.addAction(.init(title: "확인", style: .default))
        }
      }
      .disposed(by: disposeBag)
  }
}

final class CommentCell: UITableViewCell {
  static let reuseID = "CommentCell"

  private let profileImageView = UIImageView().then {
    $0.contentMode = .scaleAspectFill
    $0.clipsToBounds = true
    $0.layer.cornerRadius = 18  // 36x36 원형
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

    headerContainer.snp.makeConstraints {
      $0.top.equalToSuperview().offset(16)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.bottom.equalTo(profileImageView.snp.bottom)
    }

    profileImageView.snp.makeConstraints {
      $0.top.leading.equalToSuperview()
    }

    nameLabel.snp.makeConstraints {
      $0.leading.equalTo(profileImageView.snp.trailing).offset(6)
      $0.centerY.equalTo(profileImageView.snp.centerY)
    }

    dateLabel.snp.makeConstraints {
      $0.trailing.equalToSuperview().inset(6)
      $0.centerY.equalTo(profileImageView.snp.centerY)
    }

    contentLabel.snp.makeConstraints {
      $0.top.equalTo(headerContainer.snp.bottom).offset(10)
      $0.leading.trailing.equalToSuperview().inset(20)
      $0.bottom.equalToSuperview().inset(16)
    }
  }

  func configure(nickname: String, profileURLString: String?, date: Date, content: String) {
    nameLabel.text = nickname
    nameLabel.font = UIFont.pretendard(size: 15, weight: .medium)
    nameLabel.textColor = .black

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy.MM.dd"  // 0 패딩 포함
    dateLabel.text = formatter.string(from: date)
    dateLabel.font = UIFont.pretendard(size: 13, weight: .regular)
    dateLabel.textColor = .grayScale400

    contentLabel.text = content
    contentLabel.font = UIFont.pretendard(size: 14, weight: .regular)
    contentLabel.textColor = .grayScale900

    if let urlString = profileURLString, let url = URL(string: urlString) {
      profileImageView.kf.setImage(with: url, placeholder: UIImage.profilePerson)
    } else {
      profileImageView.image = UIImage.profilePerson
    }
  }
}

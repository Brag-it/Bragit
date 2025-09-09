//
//  LicenseDetailViewController.swift
//  Bragit
//
//  Created by 이태윤 on 9/9/25.
//
import UIKit

import SnapKit
import Then

final class LicenseDetailViewController: UIViewController {

  // 표시할 항목
  private let item: LicenseItem

  // 라이선스 전문을 보여줄 텍스트뷰
  private let textView = UITextView().then {
    $0.isEditable = false              // 편집 불가
    $0.alwaysBounceVertical = true     // 긴 텍스트 스크롤
    $0.font = .systemFont(ofSize: 14)  // 간결한 본문 폰트
    $0.textColor = .label
    $0.backgroundColor = .clear
    $0.textContainerInset = .init(top: 16, left: 16, bottom: 24, right: 16)
  }

  init(item: LicenseItem) {
    self.item = item
    super.init(nibName: nil, bundle: nil)
    self.title = item.name
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    // UI 배치
    view.addSubview(textView)
    textView.snp.makeConstraints {
      $0.edges.equalTo(view.safeAreaLayoutGuide)
    }

    // 번들에서 라이선스 파일 로드
    loadLicenseText()
  }

  // 번들 리소스에서 텍스트 파일을 읽어서 표시
  private func loadLicenseText() {
    // 파일명과 확장자를 분리해서 안전하게 로딩
    let name = item.bundleFileName
    if let url = Bundle.main.url(forResource: name, withExtension: "txt"),
       let text = try? String(contentsOf: url, encoding: .utf8) {
      textView.text = headerText() + "\n\n" + text
    } else {
      textView.text = headerText() + "\n\n(라이선스 파일을 찾을 수 없습니다: \(name).txt)"
    }
  }

  // 상단에 간단한 메타 정보 표시
  private func headerText() -> String {
    return "\(item.name)\nLicense: \(item.licenseType)"
  }
}

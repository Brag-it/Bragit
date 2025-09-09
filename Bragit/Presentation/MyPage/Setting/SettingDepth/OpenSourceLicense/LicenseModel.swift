//
//  LicenseModel.swift
//  Bragit
//
//  Created by 이태윤 on 9/9/25.
//
import Foundation

struct LicenseItem: Hashable {
  let id = UUID()
  let name: String            // 라이브러리 이름
  let licenseType: String     // 라이선스 종류
  let bundleFileName: String  // 라이선스 파일명
}

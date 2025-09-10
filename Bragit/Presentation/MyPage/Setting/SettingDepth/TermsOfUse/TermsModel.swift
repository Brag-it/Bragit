//
//  TermsModel.swift
//  Bragit
//
//  Created by 이태윤 on 9/10/25.
//
import Foundation

struct TermsItem: Hashable {
  let id = UUID()
  let name: String
  let bundleFileName: String
}

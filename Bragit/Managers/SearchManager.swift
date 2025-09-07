//
//  SearchManager.swift
//  Bragit
//
//  Created by 이태윤 on 9/8/25.
//
import Foundation

import Supabase
import RxSwift
import Dependencies

protocol SearhManagerProtocol {

}

class SearchManager: SearhManagerProtocol {
  @Dependency(\.supabase) var client


}


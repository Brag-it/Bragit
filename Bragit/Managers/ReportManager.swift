//
//  ReportManager.swift
//  Bragit
//
//  Created by seongjun cho on 9/9/25.
//

import Foundation

import Supabase
import RxSwift
import Dependencies

protocol ReportManagerProtocol {
  func rxReportUser(reportedId: String, relatedID: String) -> Observable<Void>
}

class ReportManager: ReportManagerProtocol {
  @Dependency(\.supabase) var client
  @LocalStorage(location: .nowUser) var userId: String?

  // 신고하기
  func rxReportUser(reportedId: String, relatedID: String) -> Observable<Void> {
    Observable.create { [weak self] observer in
      guard let self = self, let userId = self.userId else {
        observer.onError(
          NSError(
            domain: "UserManagerError",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "User not logged in"]
          )
        )
        return Disposables.create()
      }

      Task {
        do {
           try await self.client
            .functions
            .invoke(
              "report",
              options: FunctionInvokeOptions(
                body: [
                  "reporterId": userId,
                  "reportedId": reportedId,
                  "contentId": relatedID
                ]
              )
            )
          observer.onCompleted()
        } catch {
          print(error)
          observer.onError(error)
        }
      }

      return Disposables.create()
    }
  }
}

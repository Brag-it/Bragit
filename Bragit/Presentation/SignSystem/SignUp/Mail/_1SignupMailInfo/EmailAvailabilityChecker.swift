//
//  EmailAvailabilityChecker.swift
//  Bragit
//
//  Created by Assistant on 9/18/25.
//

import Foundation

struct EmailAvailabilityResult: Decodable {
  struct Identity: Decodable { let provider: String? }
  struct User: Decodable { let identities: [Identity]? }
  let exists: Bool
  let status: String?
  let user: User?
}

enum EmailAvailabilityCheckerError: Error, LocalizedError {
  case missingSupabaseURL
  case invalidURL
  case requestFailed(status: Int, body: String)
  case decodingFailed

  var errorDescription: String? {
    switch self {
    case .missingSupabaseURL: return "Supabase URL not configured"
    case .invalidURL: return "Invalid function URL"
    case .requestFailed(let status, let body): return "Edge function failed: status=\(status) body=\(body)"
    case .decodingFailed: return "Failed to decode edge function response"
    }
  }
}

enum EmailAvailabilityChecker {
  /// Calls the Supabase Edge Function `check-auth-user` with the given email.
  /// - Returns: `EmailAvailabilityResult` with `exists` flag and optional providers.
  static func check(email raw: String) async throws -> EmailAvailabilityResult {
    let email = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !email.isEmpty else {
      return EmailAvailabilityResult(exists: false, status: "empty", user: nil)
    }

    // Read base URL from Info.plist (same key naming used in DependencyKeys.swift)
    guard let host = Bundle.main.infoDictionary?["Supabase URL"] as? String, !host.isEmpty else {
      throw EmailAvailabilityCheckerError.missingSupabaseURL
    }

    guard let apiKey = Bundle.main.infoDictionary?["Supabase api"] as? String, !apiKey.isEmpty else {
      throw EmailAvailabilityCheckerError.requestFailed(status: 401, body: "Missing Supabase anon api key")
    }

    // Build function URL: https://<host>/functions/v1/check-auth-user
    let urlString = "https://\(host)/functions/v1/check-auth-user"
    guard let url = URL(string: urlString) else { throw EmailAvailabilityCheckerError.invalidURL }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue(apiKey, forHTTPHeaderField: "apikey")
    request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email])

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw EmailAvailabilityCheckerError.requestFailed(
        status: -1,
        body: "No HTTP response"
      )
    }

    if !(200...299).contains(http.statusCode) {
      let body = String(data: data, encoding: .utf8) ?? ""
      throw EmailAvailabilityCheckerError.requestFailed(status: http.statusCode, body: body)
    }

    do {
      let decoded = try JSONDecoder().decode(EmailAvailabilityResult.self, from: data)
      // Log helpful info
      if decoded.exists {
        let providers = decoded.user?.identities?.compactMap { $0.provider }.joined(separator: ", ") ?? "unknown"
        print("[EmailAvailability] exists=true providers=[\(providers)] status=\(decoded.status ?? "-")")
      } else {
        print("[EmailAvailability] exists=false status=\(decoded.status ?? "-")")
      }
      return decoded
    } catch {
      throw EmailAvailabilityCheckerError.decodingFailed
    }
  }
}

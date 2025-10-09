//
//  TestHelpers.swift
//  FirebaseAdmin
//
//  Common test utilities for Firestore tests
//

import Foundation
@testable import Firestore

/// Load ServiceAccount from file path or environment variables
func loadServiceAccount(from jsonFile: String = "ServiceAccount") throws -> ServiceAccount {
    // Try to load from environment variables first
    if let serviceAccount = try? ServiceAccount.loadFromEnvironment() {
        return serviceAccount
    }

    // Try to load from file in current directory
    let possiblePaths = [
        "\(jsonFile).json",
        "Tests/FirestoreTests/\(jsonFile).json",
        "../Tests/FirestoreTests/\(jsonFile).json"
    ]

    for path in possiblePaths {
        if FileManager.default.fileExists(atPath: path) {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoder = JSONDecoder()
            return try decoder.decode(ServiceAccount.self, from: data)
        }
    }

    throw NSError(domain: "FileNotFoundError", code: 404, userInfo: [NSLocalizedDescriptionKey: "ServiceAccount not found. Please set environment variables or provide \(jsonFile).json"])
}

/// Initialize FirebaseApp for testing
/// This should be called once before running tests
func initializeFirebaseForTesting() throws {
    let serviceAccount = try loadServiceAccount()
    FirebaseApp.initialize(serviceAccount: serviceAccount)
}

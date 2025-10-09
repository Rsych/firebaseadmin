//
//  TestHelpers.swift
//  FirebaseAdmin
//
//  Common test utilities for Firestore tests
//

import Foundation
@testable import Firestore

/// Load environment variables from .env file
/// Supports simple KEY=VALUE format with # for comments
func loadDotEnv() {
    let possiblePaths = [
        ".env",
        "../.env",
        "../../.env"
    ]

    for path in possiblePaths {
        guard FileManager.default.fileExists(atPath: path) else { continue }
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else { continue }

        let lines = contents.components(separatedBy: .newlines)
        for line in lines {
            // Skip empty lines and comments
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Parse KEY=VALUE
            guard let equalsIndex = trimmed.firstIndex(of: "=") else { continue }
            let key = String(trimmed[..<equalsIndex]).trimmingCharacters(in: .whitespaces)
            let value = String(trimmed[trimmed.index(after: equalsIndex)...]).trimmingCharacters(in: .whitespaces)

            // Remove quotes if present
            var finalValue = value
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
               (value.hasPrefix("'") && value.hasSuffix("'")) {
                finalValue = String(value.dropFirst().dropLast())
            }

            // Set environment variable if not already set
            if getenv(key) == nil {
                setenv(key, finalValue, 1)
            }
        }

        // Successfully loaded .env file
        return
    }
}

/// Find project root directory by looking for Package.swift
func findProjectRoot() -> String? {
    // Try environment variable first (most reliable)
    if let envRoot = ProcessInfo.processInfo.environment["FIREBASEADMIN_PROJECT_ROOT"] {
        return envRoot
    }

    // Try using #filePath (Swift 5.3+) which gives us the source file path
    let sourceFilePath = #filePath
    var currentPath = URL(fileURLWithPath: sourceFilePath)

    // Traverse up the directory tree looking for Package.swift
    for _ in 0..<10 {
        currentPath.deleteLastPathComponent()
        let packageSwiftPath = currentPath.appendingPathComponent("Package.swift").path
        if FileManager.default.fileExists(atPath: packageSwiftPath) {
            return currentPath.path
        }
    }

    // Fallback: try common locations relative to working directory
    let workingDir = FileManager.default.currentDirectoryPath
    let commonRoots = [
        workingDir,
        URL(fileURLWithPath: workingDir).deletingLastPathComponent().path,
        URL(fileURLWithPath: workingDir).deletingLastPathComponent().deletingLastPathComponent().path
    ]

    for root in commonRoots {
        let packageSwiftPath = "\(root)/Package.swift"
        if FileManager.default.fileExists(atPath: packageSwiftPath) {
            return root
        }
    }

    return nil
}

/// Load ServiceAccount from file path or environment variables
func loadServiceAccount(from jsonFile: String = "ServiceAccount") throws -> ServiceAccount {
    // Load .env file first
    loadDotEnv()

    // Try to load from environment variables first
    if let serviceAccount = try? ServiceAccount.loadFromEnvironment() {
        return serviceAccount
    }

    // Get current directory and project root
    let currentDir = FileManager.default.currentDirectoryPath
    let projectRoot = findProjectRoot()

    // Build search paths using project root
    var possiblePaths: [String] = []

    if let root = projectRoot {
        // Absolute paths from project root
        possiblePaths.append(contentsOf: [
            "\(root)/\(jsonFile).json",
            "\(root)/Tests/\(jsonFile).json",
            "\(root)/Tests/FirestoreTests/\(jsonFile).json"
        ])
    }

    // Also try relative paths from current directory
    possiblePaths.append(contentsOf: [
        "\(jsonFile).json",
        "Tests/\(jsonFile).json",
        "Tests/FirestoreTests/\(jsonFile).json",
        "../Tests/\(jsonFile).json",
        "../Tests/FirestoreTests/\(jsonFile).json",
        "../../Tests/\(jsonFile).json",
        "../../Tests/FirestoreTests/\(jsonFile).json"
    ])

    for path in possiblePaths {
        if FileManager.default.fileExists(atPath: path) {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoder = JSONDecoder()
            return try decoder.decode(ServiceAccount.self, from: data)
        }
    }

    let errorMessage = """
    ServiceAccount not found. Please provide credentials using one of these methods:
    1. Set environment variables (FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, etc.)
    2. Create a .env file in the project root
    3. Place ServiceAccount.json in one of these locations:
       - Tests/ServiceAccount.json
       - Tests/FirestoreTests/ServiceAccount.json
       - Project root directory

    Current directory: \(currentDir)
    Project root: \(projectRoot ?? "not found")
    Searched paths:
    \(possiblePaths.map { "  - \($0)" }.joined(separator: "\n"))
    """

    throw NSError(domain: "FileNotFoundError", code: 404, userInfo: [NSLocalizedDescriptionKey: errorMessage])
}

/// Global Firebase initialization for tests
/// Initialized lazily on first access - guaranteed to run only once
private let firebaseInitializer: Void = {
    print("[TestHelpers] 🔧 Starting Firebase initialization...")
    do {
        let serviceAccount = try loadServiceAccount()
        print("[TestHelpers] ✅ ServiceAccount loaded")
        FirebaseApp.initialize(serviceAccount: serviceAccount)
        print("[TestHelpers] ✅ FirebaseApp initialized")
    } catch {
        print("[TestHelpers] ❌ Failed to initialize: \(error)")
        fatalError("Failed to initialize Firebase for testing: \(error)")
    }
}()

/// Ensure Firebase is initialized for testing
/// This function can be called multiple times safely - initialization happens only once
func initializeFirebaseForTesting() {
    _ = firebaseInitializer
}

//
//  FirebaseApp.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/07.
//

import Foundation

public final class FirebaseApp: @unchecked Sendable {
    private static let _app = FirebaseApp()
    public static var app: FirebaseApp {
        get { _app }
    }
    
    private let lock = NSLock()
    private var _serviceAccount: ServiceAccount?
    
    private init() {}
    
    public var serviceAccount: ServiceAccount? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _serviceAccount
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _serviceAccount = newValue
        }
    }
    
    public static func initialize(fileName: String = "ServiceAccount") {
        do {
            let serviceAccount = try loadServiceAccount(from: fileName)
            initialize(serviceAccount: serviceAccount)
        } catch {
            fatalError("Service Account is not found.")
        }
    }
    
    public static func initialize(serviceAccount: ServiceAccount) {
        app.serviceAccount = serviceAccount
    }
    
    public static func loadServiceAccount(from jsonFile: String) throws -> ServiceAccount {
        guard let path = Bundle.main.path(forResource: jsonFile, ofType: "json") else {
            throw NSError(domain: "FileNotFoundError", code: 404, userInfo: [NSLocalizedDescriptionKey: "JSON file not found"])
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let decoder = JSONDecoder()
            let serviceAccount = try decoder.decode(ServiceAccount.self, from: data)
            return serviceAccount
        } catch {
            throw NSError(domain: "JSONParsingError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Error parsing JSON file: \(error)"])
        }
    }
    
    public func getServiceAccount() throws -> ServiceAccount {
        guard let serviceAccount = self.serviceAccount else {
            throw NSError(domain: "ServiceAccountError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Service Account is not initialized"])
        }
        return serviceAccount
    }

    // MARK: - Environment Variable Initialization

    /// Initialize from environment variables
    ///
    /// Reads Firebase service account configuration from environment variables:
    /// - `FIREBASE_PROJECT_ID`
    /// - `FIREBASE_PRIVATE_KEY_ID`
    /// - `FIREBASE_PRIVATE_KEY`
    /// - `FIREBASE_CLIENT_EMAIL`
    /// - `FIREBASE_CLIENT_ID`
    ///
    /// Example:
    /// ```bash
    /// export FIREBASE_PROJECT_ID="my-project"
    /// export FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----..."
    /// export FIREBASE_CLIENT_EMAIL="firebase-adminsdk@my-project.iam.gserviceaccount.com"
    /// export FIREBASE_CLIENT_ID="123456789"
    /// export FIREBASE_PRIVATE_KEY_ID="key-id"
    /// ```
    ///
    /// ```swift
    /// try FirebaseApp.initializeFromEnvironment()
    /// ```
    public static func initializeFromEnvironment() throws {
        let serviceAccount = try ServiceAccount.loadFromEnvironment()
        initialize(serviceAccount: serviceAccount)
    }

    /// Initialize with hierarchical configuration (async)
    ///
    /// Priority order:
    /// 1. Environment variables (highest)
    /// 2. JSON file (if provided)
    ///
    /// Example:
    /// ```swift
    /// // Environment variables only
    /// try await FirebaseApp.initializeFromConfiguration()
    ///
    /// // With JSON file fallback
    /// try await FirebaseApp.initializeFromConfiguration(jsonPath: "config/firebase.json")
    /// ```
    public static func initializeFromConfiguration(jsonPath: String? = nil) async throws {
        let serviceAccount = try await ServiceAccount.loadFromConfiguration(jsonPath: jsonPath)
        initialize(serviceAccount: serviceAccount)
    }
}

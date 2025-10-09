//
//  FirebaseMessaging.swift
//
//
//  Created by Vamsi Madduluri on 04/07/24.
//

import Foundation
import Synchronization
import AsyncHTTPClient
@_exported import FirebaseApp

// MARK: - Messaging Factory

/// Internal factory for managing MessagingClient instances per app
internal final class MessagingClientFactory: Sendable {
    static let shared = MessagingClientFactory()

    private let cache = Mutex<[String: MessagingClient]>([:])

    private init() {}

    func getOrCreate(for app: FirebaseApp) -> MessagingClient {
        return cache.withLock { cache in
            // Return cached instance if available
            if let cached = cache[app.name] {
                return cached
            }

            // Create new instance
            let messagingClient = MessagingClient(serviceAccount: app.serviceAccount)
            cache[app.name] = messagingClient
            return messagingClient
        }
    }

    func clear(for appName: String) {
        cache.withLock { cache in
            _ = cache.removeValue(forKey: appName)
        }
    }

    func clearAll() {
        cache.withLock { cache in
            cache.removeAll()
        }
    }
}

// MARK: - FirebaseApp Extension

/**
 Extension providing Messaging factory method on FirebaseApp.
 */
extension FirebaseApp {

    /**
     Returns a `MessagingClient` instance for this app.

     Use this method to obtain a `MessagingClient` instance that is initialized with this app's
     service account. The instance is cached per app, so subsequent calls return the same instance.

     Example:
     ```swift
     let app = try FirebaseApp.initialize(serviceAccount: serviceAccount)
     let messaging = app.messaging()
     ```

     - Returns: A `MessagingClient` instance initialized with this app's service account.
     */
    public func messaging() -> MessagingClient {
        return MessagingClientFactory.shared.getOrCreate(for: self)
    }
}

// MARK: - FirebaseMessaging

/**
 A class that provides convenient access to Firebase Cloud Messaging.

 The `FirebaseMessaging` class provides static methods for accessing MessagingClient instances
 from FirebaseApp instances.
 */
public class FirebaseMessaging {

    /**
     Returns a `MessagingClient` instance initialized with the default `FirebaseApp` instance.

     This is a convenience method that gets the default FirebaseApp and returns its MessagingClient instance.

     Example:
     ```swift
     // Initialize default app first
     try FirebaseApp.initialize(serviceAccount: serviceAccount)

     // Get Messaging from default app
     let messaging = try FirebaseMessaging.getMessaging()
     ```

     - Returns: A `MessagingClient` instance initialized with the default `FirebaseApp` instance.
     - Throws: Error if default app is not initialized
     */
    public static func getMessaging() throws -> MessagingClient {
        let app = try FirebaseApp.app()
        return app.messaging()
    }

    /**
     Returns a `MessagingClient` instance for the specified app.

     - Parameter app: The `FirebaseApp` instance to use.
     - Returns: A `MessagingClient` instance initialized with the app's service account.
     */
    public static func getMessaging(app: FirebaseApp) -> MessagingClient {
        return app.messaging()
    }
}

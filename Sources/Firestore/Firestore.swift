import Foundation
@_exported import FirestoreAPI
@_exported import FirebaseApp
@_exported import GRPCNIOTransportHTTP2

/**
 A typealias for Firestore with HTTP2 transport using NIO.

 This is the default transport implementation for Firestore.
 */
public typealias FirestoreHTTP2 = Firestore<HTTP2ClientTransport.Posix>

/**
 Extension providing convenience methods for creating Firestore instances.
 */
extension Firestore where Transport == HTTP2ClientTransport.Posix {

    /**
     A struct that represents an access scope for the Firestore database.

     The `Scope` struct conforms to the `AccessScope` protocol and provides a single read-only property that returns the URL for the access scope required for accessing the Firestore database.
     */
    struct Scope: FirestoreAPI.AccessScope {

        /// The URL for the access scope required for accessing the Firestore database.
        public var value: String { "https://www.googleapis.com/auth/cloud-platform" }
    }

    /// Cached Firestore instance (singleton)
    private nonisolated(unsafe) static var cachedInstance: Firestore<HTTP2ClientTransport.Posix>?
    private static let cacheLock = NSLock()

    /**
     Returns a `Firestore` instance initialized with the default `FirebaseApp` instance.

     - Parameter app: The `FirebaseApp` instance to use for authenticating with the Firestore database.

     Use this method to obtain a `Firestore` instance that is initialized with the default `FirebaseApp` instance. This is useful if your app uses only one Firebase project and you need to access only one Firestore database.

     - Returns: A `Firestore` instance initialized with the default `FirebaseApp` instance.
     */
    public static func firestore(app: FirebaseApp = FirebaseApp.app) throws -> Firestore<HTTP2ClientTransport.Posix> {
        // Check cache first
        cacheLock.lock()
        if let cached = cachedInstance {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        guard let serviceAccount = app.serviceAccount else {
            throw NSError(domain: "ServiceAccountError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Service Account is not initialized"])
        }

        let transport = try HTTP2ClientTransport.Posix(
            target: .dns(host: "firestore.googleapis.com", port: 443),
            transportSecurity: .tls,
            config: .defaults(configure: { $0.http2.targetWindowSize = 65535 })
        )

        let accessTokenProvider = try AccessTokenProvider(serviceAccount: serviceAccount)

        let firestore = Firestore(
            projectId: serviceAccount.projectId,
            transport: transport,
            accessTokenProvider: accessTokenProvider
        )

        // Cache the instance
        cacheLock.lock()
        cachedInstance = firestore
        cacheLock.unlock()

        return firestore
    }

    /**
     Retrieves an access token for the Firestore database.

     Use this method to retrieve an access token for the Firestore database. If an access token has already been retrieved, this method returns it. Otherwise, it initializes an `AccessTokenProvider` instance with the `FirebaseApp` service account and retrieves a new access token using the `Scope` struct. The access token is then stored in the `accessToken` property of the `Firestore` instance and returned.

     - Returns: An access token for the Firestore database.
     - Throws: A `ServiceAccountError` if an error occurs while initializing the `AccessTokenProvider` instance or retrieving the access token.
     */
    func getAccessToken() async throws -> String? {
        return try await accessTokenProvider?.getAccessToken(expirationDuration: 3600)
    }
}

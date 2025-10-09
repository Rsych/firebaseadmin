# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

FirebaseAdmin is a Swift package that provides a server-side interface to Firebase services (Firestore, Auth, Messaging, AppCheck). It's designed for Swift server applications and follows Swift 6 concurrency patterns.

## Build & Test Commands

```bash
# Build the entire package
swift build

# Run all tests
swift test

# Run specific test target
swift test --filter FirestoreTests

# Run a single test
swift test --filter FirestoreTests.FirestoreTests/testPath
```

**Important**: Tests require a `ServiceAccount.json` file in the `Tests/FirestoreTests/` directory. This file contains Firebase project credentials and should never be committed to version control.

## Architecture

### Core Components

1. **FirebaseApp** (Sources/FirebaseApp/)
   - Singleton that manages the Firebase service account
   - Must be initialized before using any Firebase services via `FirebaseApp.initialize(serviceAccount:)`
   - Thread-safe using NSLock for concurrent access to service account

2. **FirebaseAPIClient** (Sources/FirebaseApp/FirebaseAPIClient.swift)
   - Handles OAuth2 authentication using JWT with RSA256 signing
   - Manages HTTP requests to Firebase APIs using AsyncHTTPClient
   - Uses SwiftNIO EventLoopFuture for async operations
   - OAuth token flow: Creates JWT from service account → exchanges for OAuth token → uses token in API requests

3. **Service Modules**
   - **Firestore**: Wraps googleapis/FirebaseAPI for document/collection operations, uses gRPC-style API with HPACK headers
   - **FirebaseAuth**: User authentication management via AuthClient
   - **FirebaseMessaging**: FCM message sending via MessagingClient
   - **AppCheck**: Server-side App Check token verification for protecting backend APIs from unauthorized clients

### Authentication Flow

All services follow this pattern:
1. Get ServiceAccount from FirebaseApp singleton
2. Create JWT signed with service account's private key (RS256)
3. Exchange JWT for OAuth access token
4. Use OAuth token as Bearer token in API requests

### Firestore Integration

Firestore uses the FirebaseAPI package (github.com/1amageek/FirebaseAPI) which wraps Google's googleapis:
- DocumentReference and CollectionReference provide CRUD operations
- Built-in Codable support for Firestore types (Timestamp, GeoPoint, DocumentReference)
- Property wrappers: `@DocumentID` (auto-populated, not saved at top level), `@ExplicitNull` (explicit nil encoding)
- Access tokens obtained via AccessTokenProvider, attached as HPACK headers

### AppCheck Integration

AppCheck provides server-side verification of App Check tokens sent by client applications:
- **JWKS Endpoint**: `https://firebaseappcheck.googleapis.com/v1/jwks` (App Check-specific, not Firebase Auth)
- **Token Verification**: Validates JWT signatures using RS256 algorithm with public keys from JWKS
- **Claims Validation**: Verifies issuer, audience (project ID/number), and expiration
- **JWKS Caching**: Public keys cached for 6 hours (Firebase recommendation) with automatic refresh
- **Actor-based**: Thread-safe implementation using Swift 6 actor pattern
- **Token Source**: Clients send App Check tokens in `X-Firebase-AppCheck` HTTP header

#### AppCheck Token Structure
- `iss`: Issuer - `https://firebaseappcheck.googleapis.com/<project-number>`
- `sub`: Subject - Firebase App ID
- `aud`: Audience - Array of project identifiers (`projects/<project-id>` or `projects/<project-number>`)
- `exp`: Expiration timestamp
- `iat`: Issued at timestamp

### Concurrency

- Targets use Swift 6 strict concurrency (`StrictConcurrency=targeted` or `StrictConcurrency`)
- Upcoming features enabled: `DisableOutwardActorInference`, `SWIFT_UPCOMING_FEATURE_FORWARD_TRAILING_CLOSURES`
- FirebaseApp marked `@unchecked Sendable` with internal locking
- EventLoopFuture-based async operations (not async/await in FirebaseAPIClient)

## Package Structure

- **Products**: FirebaseApp, AppCheck, Firestore, FirebaseAuth, FirebaseMessaging
- **Key Dependencies**: AsyncHTTPClient (HTTP), JWTKit (auth), FirebaseAPI (Firestore), AnyCodable (Auth)
- **Platforms**: iOS 15+, macOS 10.15+

## Development Workflow

1. Add `ServiceAccount.json` to `Tests/FirestoreTests/` (obtain from Firebase Console)
2. The test targets use `Bundle.module.path(forResource:ofType:)` to load the service account
3. Initialize FirebaseApp in test setUp: `FirebaseApp.initialize(serviceAccount: serviceAccount)`
4. Use `try Firestore.firestore()` or `try FirebaseAuth.auth()` to get service instances

## Common Patterns

**Initialize app:**
```swift
let serviceAccount = try FirebaseApp.loadServiceAccount(from: "ServiceAccount")
FirebaseApp.initialize(serviceAccount: serviceAccount)
```

**Firestore operations:**
```swift
let firestore = try Firestore.firestore()
let ref = firestore.collection("users").document("userId")
try await ref.setData(userData)
let data = try await ref.getDocument(type: User.self)
```

**Auth operations:**
```swift
let auth = try FirebaseAuth.auth()
// Use auth client methods
```

**Messaging:**
```swift
let messaging = try FirebaseMessaging.getMessaging()
// Send FCM messages
```

**AppCheck operations:**
```swift
// Initialize with explicit project ID
let appCheck = AppCheck(projectID: "your-project-id")

// Or initialize from FirebaseApp (uses serviceAccount.projectId)
let appCheck = try AppCheck()

// Verify App Check token from client request
let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
let token = request.headers["X-Firebase-AppCheck"].first ?? ""

do {
    let payload = try await appCheck.verifyToken(token, client: httpClient)
    print("Valid token from app: \(payload.sub.value)")
    // Proceed with request processing
} catch AppCheckError.invalidAudience(let expected, let actual) {
    // Token audience mismatch
    throw Abort(.unauthorized, reason: "Invalid app")
} catch AppCheckError.expiredToken {
    // Token expired
    throw Abort(.unauthorized, reason: "Token expired")
} catch {
    // Other verification errors
    throw Abort(.unauthorized, reason: "Invalid App Check token")
}

// Clear JWKS cache (forces refresh on next verification)
await appCheck.clearCache()
```

## Important Notes

- ServiceAccount.json contains sensitive credentials - never commit it
- All async operations in FirebaseAPIClient use EventLoopFuture, not async/await
- Firestore uses HPACK headers (from NIOHPACK) for gRPC-style API communication
- The package re-exports FirebaseApp and FirestoreAPI types for convenience

### AppCheck Specific Notes

- **Correct JWKS Endpoint**: Use `https://firebaseappcheck.googleapis.com/v1/jwks` (NOT the Firebase Auth endpoint)
- **JWKS Caching**: Public keys are cached for 6 hours as recommended by Firebase to reduce API calls
- **Token Header**: Clients must send App Check tokens in the `X-Firebase-AppCheck` HTTP header
- **Actor Isolation**: AppCheck is implemented as an actor for thread-safety in Swift 6
- **Sendable Compliance**: Uses `@preconcurrency import JWTKit` for compatibility with non-Sendable JWT types
- **Validation Levels**:
  - Basic: JWT signature + expiration (always performed)
  - Enhanced: Issuer validation (requires project number)
  - Strict: Audience validation (requires project ID, always performed)
- **Error Handling**: AppCheckError provides detailed error cases for debugging (invalid issuer, audience mismatch, etc.)

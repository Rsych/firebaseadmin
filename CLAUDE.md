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

### Test Configuration

Tests require Firebase credentials. You have **three options**:

#### Option 1: Environment Variables (.env file) - Recommended
1. Copy `.env.example` to `.env`
2. Fill in your Firebase credentials:
```bash
cp .env.example .env
# Edit .env with your Firebase project credentials
```

The `.env` file supports:
- Simple `KEY=VALUE` format
- Comments with `#`
- Quoted values (single or double quotes)
- Multi-line values (for private keys)

Example:
```bash
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@your-project.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=123456789
FIREBASE_PRIVATE_KEY_ID=abc123
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
...your private key...
-----END PRIVATE KEY-----"
```

#### Option 2: System Environment Variables
Set environment variables in your shell:
```bash
export FIREBASE_PROJECT_ID=your-project-id
export FIREBASE_CLIENT_EMAIL=firebase-adminsdk@your-project.iam.gserviceaccount.com
# ... other variables
```

#### Option 3: ServiceAccount.json file
Place `ServiceAccount.json` in one of the following locations (download from Firebase Console):
- `Tests/ServiceAccount.json` (recommended - easier to manage)
- `Tests/FirestoreTests/ServiceAccount.json` (original location)
- Project root directory `ServiceAccount.json`

**Priority**: Environment variables (.env or system) > ServiceAccount.json file

**Important**: Never commit credentials (.env files or ServiceAccount.json) to version control.

## Architecture

### Core Components

1. **FirebaseApp** (Sources/FirebaseApp/)
   - Multi-instance registry that manages Firebase app configurations
   - Supports multiple named instances for connecting to different Firebase projects
   - Must be initialized before using any Firebase services via `FirebaseApp.initialize(serviceAccount:)`
   - Thread-safe using `Mutex` (Swift Synchronization framework) for concurrent access
   - Each app instance holds an immutable `ServiceAccount` configuration

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
1. Get ServiceAccount from FirebaseApp instance
2. Create JWT signed with service account's private key (RS256)
3. Exchange JWT for OAuth access token
4. Use OAuth token as Bearer token in API requests

### Service Factory Pattern

Each service (Firestore, Auth, Messaging) uses a factory pattern:
- Factory classes (`FirestoreFactory`, `AuthClientFactory`, `MessagingClientFactory`) cache service instances per app
- Services are accessed via `FirebaseApp` extension methods (e.g., `app.firestore()`)
- Convenience methods allow access to default app services (e.g., `Firestore.firestore()`)
- All factories are thread-safe using `Mutex` and conform to `Sendable`

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
- FirebaseApp and all factory classes use `Mutex` from Swift Synchronization framework for thread-safety
- All shared state is protected with `Mutex<T>` for type-safe, deadlock-free concurrent access
- Factory classes are `final` and conform to `Sendable` for Swift 6 compliance
- EventLoopFuture-based async operations (not async/await in FirebaseAPIClient)

## Package Structure

- **Products**: FirebaseApp, AppCheck, Firestore, FirebaseAuth, FirebaseMessaging
- **Key Dependencies**: AsyncHTTPClient (HTTP), JWTKit (auth), FirebaseAPI (Firestore), AnyCodable (Auth)
- **Platforms**: iOS 15+, macOS 10.15+

## Development Workflow

1. Add `ServiceAccount.json` to `Tests/` or use environment variables (see Test Configuration above)
2. Initialize FirebaseApp before using any services
3. Access services via the app instance or convenience methods
4. Clean up apps when done (especially in tests)

## Common Patterns

### Initialize FirebaseApp

**Option 1: Default app (recommended for single project)**
```swift
let serviceAccount = try ServiceAccount.load(from: "ServiceAccount.json")
let app = try FirebaseApp.initialize(serviceAccount: serviceAccount)
```

**Option 2: Named apps (for multiple projects)**
```swift
let account1 = try ServiceAccount.load(from: "Project1.json")
let account2 = try ServiceAccount.load(from: "Project2.json")

let app1 = try FirebaseApp.initialize(name: "project1", serviceAccount: account1)
let app2 = try FirebaseApp.initialize(name: "project2", serviceAccount: account2)
```

**Option 3: From environment variables**
```swift
let app = try FirebaseApp.initializeFromEnvironment()
```

### Access Services

**Option A: Via app instance (recommended - explicit dependency)**
```swift
let app = try FirebaseApp.app()
let firestore = try app.firestore()
let auth = app.auth()
let messaging = app.messaging()
let appCheck = app.appCheck()
```

**Option B: Via convenience methods (implicit default app)**
```swift
let firestore = try Firestore.firestore()
let auth = try FirebaseAuth.auth()
let messaging = try FirebaseMessaging.getMessaging()
```

### Firestore Operations
```swift
let app = try FirebaseApp.initialize(serviceAccount: serviceAccount)
let firestore = try app.firestore()

// Document operations
let ref = firestore.collection("users").document("userId")
try await ref.setData(userData)
let data = try await ref.getDocument(type: User.self)

// Query operations
let snapshot = try await firestore.collection("users")
    .where(field: "age", isGreaterThan: 18)
    .order(by: "name")
    .getDocuments()
```

### Auth Operations
```swift
let app = try FirebaseApp.app()
let auth = app.auth()

// Create custom token
let token = try await auth.createCustomToken(uid: "user123")

// Verify ID token
let decodedToken = try await auth.verifyIdToken(token)
```

### Messaging Operations
```swift
let app = try FirebaseApp.app()
let messaging = app.messaging()

// Send message
try await messaging.send(message: fcmMessage)
```

### AppCheck Operations

**Option 1: Via FirebaseApp instance**
```swift
let app = try FirebaseApp.app()
let appCheck = app.appCheck()
```

**Option 2: With explicit project ID**
```swift
let appCheck = AppCheck(projectID: "your-project-id")
```

**Option 3: From default app (convenience)**
```swift
let appCheck = try AppCheck()  // Uses default FirebaseApp
```

**Verify tokens:**
```swift
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

### Multiple Projects

**Connecting to multiple Firebase projects:**
```swift
// Initialize multiple apps
let prodApp = try FirebaseApp.initialize(
    name: "production",
    serviceAccount: prodAccount
)

let stagingApp = try FirebaseApp.initialize(
    name: "staging",
    serviceAccount: stagingAccount
)

// Access services from different projects
let prodFirestore = try prodApp.firestore()
let stagingFirestore = try stagingApp.firestore()

// Cleanup
try prodApp.delete()
try stagingApp.delete()
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

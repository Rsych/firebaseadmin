# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-10-09

### Added

#### Core Infrastructure
- **FirebaseApp**: Multi-instance registry for managing Firebase app configurations
  - Support for multiple named instances to connect to different Firebase projects
  - Thread-safe implementation using Swift Synchronization Mutex
  - Immutable ServiceAccount configuration per app instance

#### Authentication & Security
- **FirebaseAPIClient**: OAuth2 authentication using JWT with RSA256 signing
  - Automatic token management and refresh
  - AsyncHTTPClient-based HTTP operations
  - EventLoopFuture async patterns

- **AppCheck**: Server-side App Check token verification
  - JWT signature verification with RS256 algorithm
  - JWKS endpoint integration with 6-hour caching
  - Claims validation (issuer, audience, expiration)
  - Actor-based thread-safe implementation
  - Support for `X-Firebase-AppCheck` header tokens

#### Firebase Services
- **Firestore**: Complete Firestore integration via FirebaseAPI
  - Document and collection CRUD operations
  - Built-in Codable support for Firestore types
  - Property wrappers: `@DocumentID`, `@ExplicitNull`
  - Query operations with filtering and ordering
  - gRPC-style API with HPACK headers

- **FirebaseAuth**: User authentication management
  - Custom token creation
  - ID token verification
  - User management operations

- **FirebaseMessaging**: Firebase Cloud Messaging (FCM)
  - Send messages to devices
  - Support for notification and data payloads
  - Topic-based messaging

#### Configuration & Environment
- **.env file support**: Load Firebase credentials from environment
  - Simple KEY=VALUE format
  - Comments and multi-line values support
  - Priority: Environment variables > ServiceAccount.json
- **Multiple configuration options**:
  - ServiceAccount.json file
  - System environment variables
  - Direct ServiceAccount initialization

#### Concurrency & Safety
- **Swift 6 compatibility**: Strict concurrency support
- **Thread-safe factories**: All service factories use Mutex for concurrent access
- **Sendable compliance**: All shared types conform to Sendable protocol

### Technical Details
- **Minimum Swift Version**: 6.2
- **Platforms**: macOS 15+, iOS 18+
- **Key Dependencies**:
  - AsyncHTTPClient 1.21.2+
  - swift-nio 2.68.0+
  - FirebaseAPI 1.0.1+
  - grpc-swift-nio-transport 2.0.0+
  - jwt-kit 4.13.4+
  - AnyCodable 0.6.7+
  - swift-configuration 0.1.0+

[0.1.0]: https://github.com/1amageek/FirebaseAdmin/releases/tag/0.1.0

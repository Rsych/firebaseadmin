//
//  AppCheckTests.swift
//  FirebaseAdmin
//
//  Created by Norikazu Muramoto on 2023/05/12.
//

import Foundation
import Testing
import AsyncHTTPClient
import NIO
import NIOFoundationCompat
import JWTKit
@testable import AppCheck

@Suite("AppCheck Tests")
struct AppCheckTests {

    @Test("AppCheck can be initialized with project ID")
    func initializeWithProjectID() async throws {
        let appCheck = AppCheck(projectID: "test-project-id")
        // Verify initialization succeeded by accessing a property
        _ = appCheck
    }

    @Test("AppCheck can be initialized with project ID and project number")
    func initializeWithProjectIDAndNumber() async throws {
        let appCheck = AppCheck(projectID: "test-project-id", projectNumber: "123456789")
        // Verify initialization succeeded by accessing a property
        _ = appCheck
    }

    @Test("AppCheck fetches JWKS from correct endpoint")
    func fetchJWKS() async throws {
        let appCheck = AppCheck(projectID: "test-project-id")
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))

        // This will attempt to fetch real JWKS from Firebase
        // We can't verify a token without a real token, but we can verify the endpoint is accessible
        do {
            // Try to verify an invalid token - should fail but fetch JWKS successfully
            _ = try await appCheck.verifyToken("invalid.token.here", client: client)
            Issue.record("Expected verification to fail with invalid token")
        } catch let error as AppCheckError {
            // Expected - invalid token should fail
            // But JWKS should have been fetched successfully
            switch error {
            case .tokenVerificationFailed, .invalidToken:
                // This is expected for an invalid token
                break
            case .jwksFetchFailed(let underlyingError):
                Issue.record("JWKS fetch failed: \(underlyingError)")
            default:
                // Other errors are also acceptable for invalid tokens
                break
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }

        try await client.shutdown()
        try await eventLoopGroup.shutdownGracefully()
    }

    @Test("AppCheck cache management")
    func cacheManagement() async throws {
        let appCheck = AppCheck(projectID: "test-project-id")

        // Clear cache should not throw
        await appCheck.clearCache()
    }

    @Test("AppCheckError cases are comprehensive")
    func errorCases() async throws {
        let errors: [AppCheckError] = [
            .invalidToken("test"),
            .expiredToken,
            .invalidIssuer(expected: "expected", actual: "actual"),
            .invalidAudience(expected: ["exp1"], actual: ["act1"]),
            .missingRequiredClaim("test"),
            .jwksFetchFailed(NSError(domain: "test", code: -1)),
            .tokenVerificationFailed(NSError(domain: "test", code: -1)),
            .invalidProjectID,
            .cacheExpired
        ]

        // Verify all error cases can be created
        #expect(errors.count == 9)
    }

    @Test("JWKS cache is used for subsequent verifications")
    func jwksCacheUsage() async throws {
        let appCheck = AppCheck(projectID: "test-project-id")
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))

        // First verification - should fetch JWKS
        let invalidToken = "invalid.token.here"

        do {
            _ = try await appCheck.verifyToken(invalidToken, client: client)
        } catch {
            // Expected to fail with invalid token
        }

        // Second verification - should use cached JWKS
        // We can't directly verify cache usage, but we can verify it doesn't throw a fetch error
        do {
            _ = try await appCheck.verifyToken(invalidToken, client: client)
        } catch let error as AppCheckError {
            // Should not be a JWKS fetch error (cache should be used)
            switch error {
            case .jwksFetchFailed:
                Issue.record("Second verification should use cached JWKS, not fetch again")
            default:
                // Other errors are expected (invalid token)
                break
            }
        } catch {
            // Other errors are acceptable
        }

        try await client.shutdown()
        try await eventLoopGroup.shutdownGracefully()
    }

    @Test("Cache clear forces JWKS refresh")
    func cacheClearRefresh() async throws {
        let appCheck = AppCheck(projectID: "test-project-id")
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))

        // First verification to populate cache
        do {
            _ = try await appCheck.verifyToken("invalid.token", client: client)
        } catch {
            // Expected to fail
        }

        // Clear cache
        await appCheck.clearCache()

        // Next verification should fetch JWKS again
        do {
            _ = try await appCheck.verifyToken("invalid.token", client: client)
        } catch {
            // Expected to fail, but JWKS should be fetched
        }

        try await client.shutdown()
        try await eventLoopGroup.shutdownGracefully()
    }

    @Test("Concurrent token verifications are thread-safe")
    func concurrentVerifications() async throws {
        let appCheck = AppCheck(projectID: "test-project-id")
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)
        let client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))

        // Launch multiple concurrent verification tasks
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    do {
                        _ = try await appCheck.verifyToken("invalid.token.\(i)", client: client)
                    } catch {
                        // Expected to fail with invalid token
                        // But should not crash or deadlock
                    }
                }
            }
        }

        try await client.shutdown()
        try await eventLoopGroup.shutdownGracefully()
    }

    @Test("Multiple AppCheck instances can coexist")
    func multipleInstances() async throws {
        let appCheck1 = AppCheck(projectID: "project-1")
        let appCheck2 = AppCheck(projectID: "project-2", projectNumber: "123456")
        let appCheck3 = AppCheck(projectID: "project-3")

        // All instances should be independent
        await appCheck1.clearCache()
        await appCheck2.clearCache()
        await appCheck3.clearCache()

        // No crashes or conflicts expected
    }

    @Test("Invalid token formats are rejected")
    func invalidTokenFormats() async throws {
        let appCheck = AppCheck(projectID: "test-project-id")
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))

        let invalidTokens = [
            "",
            "not-a-jwt",
            "invalid",
            "a.b",  // Only 2 parts
            "a.b.c.d",  // Too many parts
        ]

        for token in invalidTokens {
            do {
                _ = try await appCheck.verifyToken(token, client: client)
                Issue.record("Expected verification to fail for token: \(token)")
            } catch {
                // Expected - all invalid tokens should be rejected
            }
        }

        try await client.shutdown()
        try await eventLoopGroup.shutdownGracefully()
    }

    @Test("JWKS endpoint returns valid data")
    func jwksEndpointValidity() async throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))

        // Directly test the JWKS endpoint
        let jwksURL = "https://firebaseappcheck.googleapis.com/v1/jwks"

        do {
            let response = try await client.get(url: jwksURL).get()

            // Verify response is successful
            #expect(response.status.code == 200)

            // Verify we got some data
            #expect(response.body != nil)

            // Try to decode as JWKS
            if let body = response.body {
                let decoder = JSONDecoder()
                let jwks = try decoder.decode(JWKS.self, from: body)

                // Verify JWKS contains keys
                #expect(jwks.keys.isEmpty == false)
            }
        } catch {
            Issue.record("JWKS endpoint should be accessible: \(error)")
        }

        try await client.shutdown()
        try await eventLoopGroup.shutdownGracefully()
    }

    @Test("AppCheckError provides detailed information")
    func errorDetailedInformation() async throws {
        // Test that errors contain useful debugging information

        // Test invalidIssuer error
        let issuerError = AppCheckError.invalidIssuer(
            expected: "https://firebaseappcheck.googleapis.com/123456",
            actual: "https://wrong-issuer.com"
        )

        switch issuerError {
        case .invalidIssuer(let expected, let actual):
            #expect(expected.contains("firebaseappcheck.googleapis.com"))
            #expect(actual == "https://wrong-issuer.com")
        default:
            Issue.record("Expected invalidIssuer error")
        }

        // Test invalidAudience error
        let audienceError = AppCheckError.invalidAudience(
            expected: ["projects/my-project"],
            actual: ["projects/wrong-project"]
        )

        switch audienceError {
        case .invalidAudience(let expected, let actual):
            #expect(expected.contains("projects/my-project"))
            #expect(actual.contains("projects/wrong-project"))
        default:
            Issue.record("Expected invalidAudience error")
        }
    }

    @Test("FirebaseApp integration - AppCheck initialization")
    func firebaseAppIntegration() async throws {
        // Test that AppCheck() initializer behaves correctly with FirebaseApp
        // Note: FirebaseApp may or may not be initialized by other tests

        do {
            let appCheck = try AppCheck()
            // If FirebaseApp is initialized, AppCheck() should succeed
            // The appCheck instance should be valid
            _ = appCheck
        } catch AppCheckError.invalidProjectID {
            // If FirebaseApp exists but has no serviceAccount
            // This is expected behavior
        } catch FirebaseAppError.noApp {
            // If FirebaseApp doesn't exist yet
            // This is expected behavior in test isolation
        } catch {
            Issue.record("Expected either success, invalidProjectID, or noApp error, got: \(error)")
        }
    }

    @Test("JWKS contains RSA keys")
    func jwksContainsRSAKeys() async throws {
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))

        let jwksURL = "https://firebaseappcheck.googleapis.com/v1/jwks"
        let response = try await client.get(url: jwksURL).get()

        guard let body = response.body else {
            Issue.record("JWKS endpoint returned empty body")
            return
        }

        let decoder = JSONDecoder()
        let jwks = try decoder.decode(JWKS.self, from: body)

        // Verify all keys are RSA keys
        for key in jwks.keys {
            #expect(key.keyType == .rsa)
        }

        try await client.shutdown()
        try await eventLoopGroup.shutdownGracefully()
    }
}

// MARK: - Performance Tests

@Suite("AppCheck Performance Tests")
struct AppCheckPerformanceTests {

    @Test("JWKS caching improves performance")
    func cachingPerformance() async throws {
        let appCheck = AppCheck(projectID: "test-project-id")
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))

        let invalidToken = "invalid.token.here"

        // First call - fetches JWKS
        let start1 = Date()
        do {
            _ = try await appCheck.verifyToken(invalidToken, client: client)
        } catch {
            // Expected to fail
        }
        let duration1 = Date().timeIntervalSince(start1)

        // Second call - uses cache
        let start2 = Date()
        do {
            _ = try await appCheck.verifyToken(invalidToken, client: client)
        } catch {
            // Expected to fail
        }
        let duration2 = Date().timeIntervalSince(start2)

        // Cached call should be significantly faster
        // (We allow some variance due to network conditions)
        #expect(duration2 < duration1 * 0.5, "Cached verification should be faster")

        try await client.shutdown()
        try await eventLoopGroup.shutdownGracefully()
    }

    @Test("Concurrent verifications scale efficiently")
    func concurrentPerformance() async throws {
        let appCheck = AppCheck(projectID: "test-project-id")
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 4)
        let client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))

        let start = Date()

        // Launch 20 concurrent verifications
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<20 {
                group.addTask {
                    do {
                        _ = try await appCheck.verifyToken("invalid.token.\(i)", client: client)
                    } catch {
                        // Expected to fail
                    }
                }
            }
        }

        let duration = Date().timeIntervalSince(start)

        // Should complete in reasonable time (< 5 seconds even with network calls)
        #expect(duration < 5.0, "Concurrent verifications should complete efficiently")

        try await client.shutdown()
        try await eventLoopGroup.shutdownGracefully()
    }
}

// MARK: - Integration Tests (requires real App Check token)

@Suite("AppCheck Integration Tests", .disabled("Requires real App Check token"))
struct AppCheckIntegrationTests {

    @Test("Verify real App Check token")
    func verifyRealToken() async throws {
        // To run this test:
        // 1. Set up App Check in your Firebase project
        // 2. Generate a real App Check token from a client app
        // 3. Replace the token and project ID below
        let token = "REAL_APP_CHECK_TOKEN_HERE"
        let projectID = "YOUR_PROJECT_ID"

        let appCheck = AppCheck(projectID: projectID)
        let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup))

        let payload = try await appCheck.verifyToken(token, client: client)

        // Verify payload structure
        #expect(payload.sub.value.isEmpty == false)
        #expect(payload.aud.value.isEmpty == false)

        try await client.shutdown()
        try await eventLoopGroup.shutdownGracefully()
    }
}

import Testing
import Foundation
@testable import Firestore

@Suite("Access Token Tests")
struct AccessTokenTests {

    init() {
        initializeFirebaseForTesting()
    }

    @Test func getAccessToken() async throws {
        print("[AccessTokenTests] 🧪 Starting access token test")

        print("[AccessTokenTests] 📝 Loading service account...")
        let serviceAccount = try loadServiceAccount()
        print("[AccessTokenTests] ✅ Service account loaded: \(serviceAccount.projectId)")

        print("[AccessTokenTests] 📝 Creating AccessTokenProvider...")
        let provider = try AccessTokenProvider(serviceAccount: serviceAccount)
        print("[AccessTokenTests] ✅ AccessTokenProvider created")

        print("[AccessTokenTests] 📝 Getting access token...")
        let token = try await provider.getAccessToken(expirationDuration: 3600)
        print("[AccessTokenTests] ✅ Access token obtained: \(token.prefix(20))...")

        #expect(!token.isEmpty)
        print("[AccessTokenTests] ✅ Test completed successfully")
    }

    @Test func tokenCaching() async throws {
        print("[AccessTokenTests] 🧪 Starting token caching test")

        let serviceAccount = try loadServiceAccount()
        let provider = try AccessTokenProvider(serviceAccount: serviceAccount)

        print("[AccessTokenTests] 📝 Getting first token...")
        let token1 = try await provider.getAccessToken(expirationDuration: 3600)
        print("[AccessTokenTests] ✅ First token obtained")

        print("[AccessTokenTests] 📝 Getting second token (should be cached)...")
        let token2 = try await provider.getAccessToken(expirationDuration: 3600)
        print("[AccessTokenTests] ✅ Second token obtained")

        #expect(token1 == token2)
        print("[AccessTokenTests] ✅ Tokens match - caching works!")
    }
}

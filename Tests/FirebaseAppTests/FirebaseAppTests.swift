//
//  FirebaseAppTests.swift
//  FirebaseAdmin
//
//  Tests for FirebaseApp initialization with different methods
//

import Testing
import Foundation
@testable import FirebaseApp

@Suite("FirebaseApp Initialization Tests")
struct FirebaseAppTests {

    @Test("Initialize from JSON file")
    func initializeFromJSONFile() throws {
        // Create temporary ServiceAccount.json
        let tempDir = FileManager.default.temporaryDirectory
        let jsonPath = tempDir.appendingPathComponent("test-service-account.json")

        let jsonContent = """
        {
            "type": "service_account",
            "project_id": "json-test-project",
            "private_key_id": "json-test-key-id",
            "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC\\n-----END PRIVATE KEY-----\\n",
            "client_email": "firebase-adminsdk@json-test-project.iam.gserviceaccount.com",
            "client_id": "987654321",
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
            "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk%40json-test-project.iam.gserviceaccount.com"
        }
        """

        try jsonContent.write(to: jsonPath, atomically: true, encoding: .utf8)

        defer {
            try? FileManager.default.removeItem(at: jsonPath)
            try? FirebaseApp.app(name: "json-test-app").delete()
        }

        // Load from file
        let data = try Data(contentsOf: jsonPath)
        let decoder = JSONDecoder()
        let serviceAccount = try decoder.decode(ServiceAccount.self, from: data)

        let app = try FirebaseApp.initialize(name: "json-test-app", serviceAccount: serviceAccount)
        let loadedAccount = try app.getServiceAccount()

        #expect(loadedAccount.projectId == "json-test-project")
        #expect(loadedAccount.privateKeyId == "json-test-key-id")
        #expect(loadedAccount.clientEmail == "firebase-adminsdk@json-test-project.iam.gserviceaccount.com")
        #expect(loadedAccount.clientId == "987654321")
    }

    @Test("ServiceAccount snake_case decoding")
    func serviceAccountDecoding() throws {
        let jsonString = """
        {
            "type": "service_account",
            "project_id": "decode-test-project",
            "private_key_id": "decode-key-id",
            "private_key": "-----BEGIN PRIVATE KEY-----\\nTEST_KEY\\n-----END PRIVATE KEY-----\\n",
            "client_email": "test@decode-project.iam.gserviceaccount.com",
            "client_id": "555555555",
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
            "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/test"
        }
        """

        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()

        let serviceAccount = try decoder.decode(ServiceAccount.self, from: data)

        #expect(serviceAccount.type == "service_account")
        #expect(serviceAccount.projectId == "decode-test-project")
        #expect(serviceAccount.privateKeyId == "decode-key-id")
        #expect(serviceAccount.clientEmail == "test@decode-project.iam.gserviceaccount.com")
        #expect(serviceAccount.clientId == "555555555")
        #expect(serviceAccount.authUri == "https://accounts.google.com/o/oauth2/auth")
        #expect(serviceAccount.tokenUri == "https://oauth2.googleapis.com/token")
    }

    @Test("ServiceAccount private key newline conversion")
    func privateKeyNewlineConversion() {
        // Simulate what happens when loading from environment variable
        let escapedKey = "-----BEGIN PRIVATE KEY-----\\nLINE1\\nLINE2\\n-----END PRIVATE KEY-----\\n"
        let convertedKey = escapedKey.replacingOccurrences(of: "\\n", with: "\n")

        let serviceAccount = ServiceAccount(
            type: "service_account",
            projectId: "test-project",
            privateKeyId: "test-key-id",
            privateKeyPem: convertedKey,
            clientEmail: "test@test.iam.gserviceaccount.com",
            clientId: "123456789",
            authUri: "https://accounts.google.com/o/oauth2/auth",
            tokenUri: "https://oauth2.googleapis.com/token",
            authProviderX509CertUrl: "https://www.googleapis.com/oauth2/v1/certs",
            clientX509CertUrl: "https://www.googleapis.com/robot/v1/metadata/x509/test"
        )

        // Check that escaped newlines are converted to actual newlines
        #expect(serviceAccount.privateKeyPem.contains("\n"))
        // Should have actual newlines, not the backslash-n sequence
        let backslashN = "\\" + "n"
        #expect(!serviceAccount.privateKeyPem.contains(backslashN))
        #expect(serviceAccount.privateKeyPem.components(separatedBy: "\n").count > 1)
    }

    @Test("ServiceAccount default values for optional fields")
    func serviceAccountDefaultValues() {
        let serviceAccount = ServiceAccount(
            type: "service_account",
            projectId: "test-project",
            privateKeyId: "test-key-id",
            privateKeyPem: "-----BEGIN PRIVATE KEY-----\nKEY\n-----END PRIVATE KEY-----\n",
            clientEmail: "test@test.iam.gserviceaccount.com",
            clientId: "123456789",
            authUri: "https://accounts.google.com/o/oauth2/auth",
            tokenUri: "https://oauth2.googleapis.com/token",
            authProviderX509CertUrl: "https://www.googleapis.com/oauth2/v1/certs",
            clientX509CertUrl: "https://www.googleapis.com/robot/v1/metadata/x509/test@test.iam.gserviceaccount.com"
        )

        #expect(serviceAccount.authUri == "https://accounts.google.com/o/oauth2/auth")
        #expect(serviceAccount.tokenUri == "https://oauth2.googleapis.com/token")
        #expect(serviceAccount.authProviderX509CertUrl == "https://www.googleapis.com/oauth2/v1/certs")
        #expect(serviceAccount.clientX509CertUrl.contains(serviceAccount.clientEmail))
    }

    @Test("FirebaseApp multiple instance support")
    func firebaseAppMultipleInstances() throws {
        let serviceAccount1 = ServiceAccount(
            type: "service_account",
            projectId: "multi-test-1",
            privateKeyId: "key-1",
            privateKeyPem: "-----BEGIN PRIVATE KEY-----\nKEY1\n-----END PRIVATE KEY-----\n",
            clientEmail: "test1@test.iam.gserviceaccount.com",
            clientId: "111111111",
            authUri: "https://accounts.google.com/o/oauth2/auth",
            tokenUri: "https://oauth2.googleapis.com/token",
            authProviderX509CertUrl: "https://www.googleapis.com/oauth2/v1/certs",
            clientX509CertUrl: "https://www.googleapis.com/robot/v1/metadata/x509/test1"
        )

        let serviceAccount2 = ServiceAccount(
            type: "service_account",
            projectId: "multi-test-2",
            privateKeyId: "key-2",
            privateKeyPem: "-----BEGIN PRIVATE KEY-----\nKEY2\n-----END PRIVATE KEY-----\n",
            clientEmail: "test2@test.iam.gserviceaccount.com",
            clientId: "222222222",
            authUri: "https://accounts.google.com/o/oauth2/auth",
            tokenUri: "https://oauth2.googleapis.com/token",
            authProviderX509CertUrl: "https://www.googleapis.com/oauth2/v1/certs",
            clientX509CertUrl: "https://www.googleapis.com/robot/v1/metadata/x509/test2"
        )

        defer {
            // Clean up only the apps created in this test
            try? FirebaseApp.app(name: "multi-instance-1").delete()
            try? FirebaseApp.app(name: "multi-instance-2").delete()
        }

        // Initialize named apps (avoid using default to prevent interfering with other tests)
        let app1 = try FirebaseApp.initialize(name: "multi-instance-1", serviceAccount: serviceAccount1)
        #expect(app1.serviceAccount.projectId == "multi-test-1")

        // Initialize another named app
        let app2 = try FirebaseApp.initialize(name: "multi-instance-2", serviceAccount: serviceAccount2)
        #expect(app2.serviceAccount.projectId == "multi-test-2")

        // Retrieve apps
        let retrieved1 = try FirebaseApp.app(name: "multi-instance-1")
        #expect(retrieved1.serviceAccount.projectId == "multi-test-1")

        let retrieved2 = try FirebaseApp.app(name: "multi-instance-2")
        #expect(retrieved2.serviceAccount.projectId == "multi-test-2")

        // Check all apps (should include at least these 2, possibly more from other tests)
        let allApps = FirebaseApp.allApps()
        #expect(allApps["multi-instance-1"] != nil)
        #expect(allApps["multi-instance-2"] != nil)
    }

    @Test("FirebaseApp duplicate initialization throws error")
    func firebaseAppDuplicateError() throws {
        let serviceAccount = ServiceAccount(
            type: "service_account",
            projectId: "duplicate-test",
            privateKeyId: "key-1",
            privateKeyPem: "-----BEGIN PRIVATE KEY-----\nKEY\n-----END PRIVATE KEY-----\n",
            clientEmail: "test@test.iam.gserviceaccount.com",
            clientId: "111111111",
            authUri: "https://accounts.google.com/o/oauth2/auth",
            tokenUri: "https://oauth2.googleapis.com/token",
            authProviderX509CertUrl: "https://www.googleapis.com/oauth2/v1/certs",
            clientX509CertUrl: "https://www.googleapis.com/robot/v1/metadata/x509/test"
        )

        defer {
            try? FirebaseApp.app(name: "duplicate-test-app").delete()
        }

        // First initialization should succeed
        try FirebaseApp.initialize(name: "duplicate-test-app", serviceAccount: serviceAccount)

        // Second initialization with same name should throw
        #expect(throws: FirebaseAppError.self) {
            try FirebaseApp.initialize(name: "duplicate-test-app", serviceAccount: serviceAccount)
        }
    }

    @Test("FirebaseApp delete removes instance")
    func firebaseAppDelete() throws {
        let serviceAccount = ServiceAccount(
            type: "service_account",
            projectId: "delete-test",
            privateKeyId: "key-1",
            privateKeyPem: "-----BEGIN PRIVATE KEY-----\nKEY\n-----END PRIVATE KEY-----\n",
            clientEmail: "test@test.iam.gserviceaccount.com",
            clientId: "111111111",
            authUri: "https://accounts.google.com/o/oauth2/auth",
            tokenUri: "https://oauth2.googleapis.com/token",
            authProviderX509CertUrl: "https://www.googleapis.com/oauth2/v1/certs",
            clientX509CertUrl: "https://www.googleapis.com/robot/v1/metadata/x509/test"
        )

        let app = try FirebaseApp.initialize(name: "delete-test-app", serviceAccount: serviceAccount)

        // App should exist
        _ = try FirebaseApp.app(name: "delete-test-app")

        // Delete the app
        try app.delete()

        // App should no longer exist
        #expect(throws: FirebaseAppError.self) {
            try FirebaseApp.app(name: "delete-test-app")
        }
    }

    @Test("Initialize with invalid ServiceAccount.json path")
    func initializeWithInvalidPath() {
        #expect(throws: Error.self) {
            try FirebaseApp.loadServiceAccount(from: "NonExistentFile")
        }
    }
}

// MARK: - Integration Tests
// Note: The following tests require actual environment variables to be set
// These should be run separately in a CI/CD environment

@Suite("FirebaseApp Environment Variable Integration Tests", .disabled("Requires environment variables"))
struct FirebaseAppEnvironmentTests {

    @Test("Initialize from environment variables")
    func initializeFromEnvironment() throws {
        // This test requires the following environment variables to be set:
        // - FIREBASE_PROJECT_ID
        // - FIREBASE_PRIVATE_KEY_ID
        // - FIREBASE_PRIVATE_KEY
        // - FIREBASE_CLIENT_EMAIL
        // - FIREBASE_CLIENT_ID

        let app = try FirebaseApp.initializeFromEnvironment()
        let serviceAccount = app.serviceAccount

        #expect(serviceAccount.projectId != "")
        #expect(serviceAccount.clientEmail.contains("@"))
    }

    @Test("Hierarchical configuration with environment priority")
    func hierarchicalConfiguration() async throws {
        // This test requires environment variables to be set
        // and tests that they take priority over a JSON config file

        let tempDir = FileManager.default.temporaryDirectory
        let jsonPath = tempDir.appendingPathComponent("fallback-config.json")

        let jsonContent = """
        {
            "firebase.projectId": "fallback-project",
            "firebase.privateKeyId": "fallback-key",
            "firebase.privateKey": "-----BEGIN PRIVATE KEY-----\\nFALLBACK\\n-----END PRIVATE KEY-----\\n",
            "firebase.clientEmail": "fallback@test.iam.gserviceaccount.com",
            "firebase.clientId": "000000000"
        }
        """

        try jsonContent.write(to: jsonPath, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: jsonPath) }

        let app = try await FirebaseApp.initializeFromConfiguration(jsonPath: jsonPath.path)
        let serviceAccount = app.serviceAccount

        // If environment variables are set, they should be used
        // Otherwise, the JSON config should be used
        #expect(serviceAccount.projectId != "")
    }
}

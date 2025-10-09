//
//  WriteBatchTests.swift
//
//
//  Created by Norikazu Muramoto on 2023/05/13.
//

import Testing
@testable import Firestore

@Suite("Write Batch Tests")
struct WriteBatchTests {

    init() {
        initializeFirebaseForTesting()
    }

    private func cleanupTestData() async throws {
        let snapshot = try await Firestore.firestore().collection("test_batch")
            .getDocuments()
        let batch = try Firestore.firestore().batch()
        snapshot.documents.forEach { snapshot in
            batch.deleteDocument(document: snapshot.documentReference)
        }
        try await batch.commit()
    }

    @Test func createWriteBatch() async throws {
        defer { Task { try? await cleanupTestData() } }

        let firestore = try Firestore.firestore()
        let batch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection("test_batch").document("batch_create_\(index)")
            batch.setData(data: ["field": index], forDocument: ref)
        }
        try await batch.commit()
        for index in (0..<5) {
            let ref = firestore.collection("test_batch").document("batch_create_\(index)")
            let snapshot = try await ref.getDocument()
            let data = snapshot.data()!
            #expect(data["field"] as! Int == index)
        }
    }

    @Test func setDataWriteBatch() async throws {
        defer { Task { try? await cleanupTestData() } }

        let firestore = try Firestore.firestore()
        let createBatch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection("test_batch").document("batch_setData_\(index)")
            createBatch.setData(data: ["count": index, "name": "name"], forDocument: ref)
        }
        try await createBatch.commit()
        let updateBatch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection("test_batch").document("batch_setData_\(index)")
            updateBatch.setData(data: ["field": index + 1], forDocument: ref)
        }
        try await updateBatch.commit()
        for index in (0..<5) {
            let ref = firestore.collection("test_batch").document("batch_setData_\(index)")
            let snapshot = try await ref.getDocument()
            let data = snapshot.data()!
            #expect(data["field"] as! Int == index + 1)
            #expect(data["name"] == nil)
        }
    }

    @Test func setDataMergeWriteBatch() async throws {
        defer { Task { try? await cleanupTestData() } }

        let firestore = try Firestore.firestore()
        let createBatch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection("test_batch").document("batch_setDataMerge_\(index)")
            createBatch.setData(data: ["count": index, "name": "name"], forDocument: ref)
        }
        try await createBatch.commit()
        let updateBatch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection("test_batch").document("batch_setDataMerge_\(index)")
            updateBatch.setData(data: ["field": index + 1], forDocument: ref, merge: true)
        }
        try await updateBatch.commit()
        for index in (0..<5) {
            let ref = firestore.collection("test_batch").document("batch_setDataMerge_\(index)")
            let snapshot = try await ref.getDocument()
            let data = snapshot.data()!
            #expect(data["field"] as! Int == index + 1)
            #expect(data["name"] as! String == "name")
        }
    }

    @Test func updateWriteBatch() async throws {
        defer { Task { try? await cleanupTestData() } }

        let firestore = try Firestore.firestore()
        let createBatch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection("test_batch").document("batch_update_\(index)")
            createBatch.setData(data: ["count": index, "name": "name"], forDocument: ref)
        }
        try await createBatch.commit()
        let updateBatch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection("test_batch").document("batch_update_\(index)")
            updateBatch.updateData(fields: ["field": index + 1], forDocument: ref)
        }
        try await updateBatch.commit()
        for index in (0..<5) {
            let ref = firestore.collection("test_batch").document("batch_update_\(index)")
            let snapshot = try await ref.getDocument()
            let data = snapshot.data()!
            #expect(data["field"] as! Int == index + 1)
            #expect(data["name"] as! String == "name")
        }
    }

    @Test func deleteWriteBatch() async throws {
        defer { Task { try? await cleanupTestData() } }

        let firestore = try Firestore.firestore()
        let createBatch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection("test_batch").document("batch_\(index)")
            createBatch.setData(data: ["field": index], forDocument: ref)
        }
        try await createBatch.commit()
        let deleteBatch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection("test_batch").document("batch_\(index)")
            deleteBatch.deleteDocument(document: ref)
        }
        try await deleteBatch.commit()
        for index in (0..<5) {
            let ref = firestore.collection("test_batch").document("batch_\(index)")
            let snapshot = try await ref.getDocument()
            #expect(snapshot.exists == false)
        }
    }

    @Test func fieldValueWriteBatch() async throws {
        defer { Task { try? await cleanupTestData() } }

        let firestore = try Firestore.firestore()
        let createBatch = firestore.batch()
        (0..<5).forEach { index in
            let timestamp = FieldValue.serverTimestamp
            let ref = firestore.collection("test_batch").document("batch_fieldvalue_\(index)")
            createBatch.setData(data: ["field": index, "timestamp": timestamp], forDocument: ref)
        }
        try await createBatch.commit()
        for index in (0..<5) {
            let ref = firestore.collection("test_batch").document("batch_fieldvalue_\(index)")
            let snapshot = try await ref.getDocument()
            let data = snapshot.data()!
            #expect(data["field"] as! Int == index)
            #expect(data["timestamp"] is Timestamp)
        }
    }

}

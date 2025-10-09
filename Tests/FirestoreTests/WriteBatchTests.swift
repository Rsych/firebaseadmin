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

    private func cleanupCollection(_ collectionID: String) async throws {
        let snapshot = try await Firestore.firestore().collection(collectionID)
            .getDocuments()
        let batch = try Firestore.firestore().batch()
        snapshot.documents.forEach { snapshot in
            batch.deleteDocument(document: snapshot.documentReference)
        }
        try await batch.commit()
    }

    @Test func createWriteBatch() async throws {
        let collectionID = "test_batch_create"
        defer { Task { try? await cleanupCollection(collectionID) } }

        let firestore = try Firestore.firestore()
        let batch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection(collectionID).document("doc_\(index)")
            batch.setData(data: ["field": index], forDocument: ref)
        }
        try await batch.commit()
        for index in (0..<5) {
            let ref = firestore.collection(collectionID).document("doc_\(index)")
            let snapshot = try await ref.getDocument()
            let data = snapshot.data()!
            #expect(data["field"] as! Int == index)
        }
    }

    @Test func setDataWriteBatch() async throws {
        let collectionID = "test_batch_setData"
        defer { Task { try? await cleanupCollection(collectionID) } }

        let firestore = try Firestore.firestore()
        let createBatch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection(collectionID).document("doc_\(index)")
            createBatch.setData(data: ["count": index, "name": "name"], forDocument: ref)
        }
        try await createBatch.commit()
        let updateBatch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection(collectionID).document("doc_\(index)")
            updateBatch.setData(data: ["field": index + 1], forDocument: ref)
        }
        try await updateBatch.commit()
        for index in (0..<5) {
            let ref = firestore.collection(collectionID).document("doc_\(index)")
            let snapshot = try await ref.getDocument()
            let data = snapshot.data()!
            #expect(data["field"] as! Int == index + 1)
            #expect(data["name"] == nil)
        }
    }

    @Test func setDataMergeWriteBatch() async throws {
        let collectionID = "test_batch_setDataMerge"
        defer { Task { try? await cleanupCollection(collectionID) } }

        let firestore = try Firestore.firestore()
        let createBatch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection(collectionID).document("doc_\(index)")
            createBatch.setData(data: ["count": index, "name": "name"], forDocument: ref)
        }
        try await createBatch.commit()
        let updateBatch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection(collectionID).document("doc_\(index)")
            updateBatch.setData(data: ["field": index + 1], forDocument: ref, merge: true)
        }
        try await updateBatch.commit()
        for index in (0..<5) {
            let ref = firestore.collection(collectionID).document("doc_\(index)")
            let snapshot = try await ref.getDocument()
            let data = snapshot.data()!
            #expect(data["field"] as! Int == index + 1)
            #expect(data["name"] as! String == "name")
        }
    }

    @Test func updateWriteBatch() async throws {
        let collectionID = "test_batch_update"
        defer { Task { try? await cleanupCollection(collectionID) } }

        let firestore = try Firestore.firestore()
        let createBatch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection(collectionID).document("doc_\(index)")
            createBatch.setData(data: ["count": index, "name": "name"], forDocument: ref)
        }
        try await createBatch.commit()
        let updateBatch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection(collectionID).document("doc_\(index)")
            updateBatch.updateData(fields: ["field": index + 1], forDocument: ref)
        }
        try await updateBatch.commit()
        for index in (0..<5) {
            let ref = firestore.collection(collectionID).document("doc_\(index)")
            let snapshot = try await ref.getDocument()
            let data = snapshot.data()!
            #expect(data["field"] as! Int == index + 1)
            #expect(data["name"] as! String == "name")
        }
    }

    @Test func deleteWriteBatch() async throws {
        let collectionID = "test_batch_delete"
        defer { Task { try? await cleanupCollection(collectionID) } }

        let firestore = try Firestore.firestore()
        let createBatch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection(collectionID).document("doc_\(index)")
            createBatch.setData(data: ["field": index], forDocument: ref)
        }
        try await createBatch.commit()
        let deleteBatch = firestore.batch()
        (0..<5).forEach { index in
            let ref = firestore.collection(collectionID).document("doc_\(index)")
            deleteBatch.deleteDocument(document: ref)
        }
        try await deleteBatch.commit()
        for index in (0..<5) {
            let ref = firestore.collection(collectionID).document("doc_\(index)")
            let snapshot = try await ref.getDocument()
            #expect(snapshot.exists == false)
        }
    }

    @Test func fieldValueWriteBatch() async throws {
        let collectionID = "test_batch_fieldValue"
        defer { Task { try? await cleanupCollection(collectionID) } }

        let firestore = try Firestore.firestore()
        let createBatch = firestore.batch()
        (0..<5).forEach { index in
            let timestamp = FieldValue.serverTimestamp
            let ref = firestore.collection(collectionID).document("doc_\(index)")
            createBatch.setData(data: ["field": index, "timestamp": timestamp], forDocument: ref)
        }
        try await createBatch.commit()
        for index in (0..<5) {
            let ref = firestore.collection(collectionID).document("doc_\(index)")
            let snapshot = try await ref.getDocument()
            let data = snapshot.data()!
            #expect(data["field"] as! Int == index)
            #expect(data["timestamp"] is Timestamp)
        }
    }

}

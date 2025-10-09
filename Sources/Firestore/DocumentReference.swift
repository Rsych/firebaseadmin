//
//  DocumentReference+gRPC.swift
//
//
//  Created by Norikazu Muramoto on 2023/04/10.
//

import Foundation

extension DocumentReference {

    public func getDocument() async throws -> DocumentSnapshot {
        let firestore = try Firestore.firestore()
        return try await getDocument(firestore: firestore)
    }

    public func setData(_ documentData: [String: Any], merge: Bool = false) async throws {
        let firestore = try Firestore.firestore()
        return try await setData(documentData, merge: merge, firestore: firestore)
    }

    public func updateData(_ fields: [String: Any]) async throws {
        let firestore = try Firestore.firestore()
        return try await updateData(fields, firestore: firestore)
    }

    public func delete() async throws {
        let firestore = try Firestore.firestore()
        return try await delete(firestore: firestore)
    }
}

extension DocumentReference {

    public func setData<T: Encodable>(_ data: T, merge: Bool = false) async throws {
        let firestore = try Firestore.firestore()
        return try await self.setData(data, merge: merge, firestore: firestore)
    }

    public func updateData<T: Encodable>(_ data: T) async throws {
        let firestore = try Firestore.firestore()
        return try await self.updateData(data, firestore: firestore)
    }
}

extension DocumentReference {

    public func getDocument<T: Decodable>(type: T.Type) async throws -> T? {
        let firestore = try Firestore.firestore()
        return try await getDocument(type: type, firestore: firestore)
    }
}

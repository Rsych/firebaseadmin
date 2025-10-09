import Testing
import Foundation
@testable import Firestore

@Suite("Document Tests")
struct DocumentTests {

    init() {
        initializeFirebaseForTesting()
    }

    @Test func serverTimestamp() async throws {
        print("[DocumentTests] 🧪 Starting serverTimestamp test")

        print("[DocumentTests] 📝 Getting Firestore instance...")
        let firestore = try Firestore.firestore()
        print("[DocumentTests] ✅ Firestore instance obtained")

        print("[DocumentTests] 📝 Getting document reference...")
        let ref = firestore
            .collection("test")
            .document("serverTimestamp")
        print("[DocumentTests] ✅ Document reference created: \(ref.path)")

        print("[DocumentTests] 📝 Setting data with serverTimestamp...")
        try await ref.setData([
            "serverTimestamp": FieldValue.serverTimestamp
        ])
        print("[DocumentTests] ✅ Data set successfully")

        print("[DocumentTests] 📝 Getting document...")
        let snapshot = try await ref.getDocument()
        print("[DocumentTests] ✅ Document retrieved")

        let data = snapshot.data()!
        #expect(data["serverTimestamp"] is Timestamp)
        print("[DocumentTests] ✅ Test completed successfully")
    }

    @Test func convertTimestampToDate() async throws {

        struct TimestampObject: Codable {
            var value: Timestamp = Timestamp(seconds: 1000, nanos: 0)
        }

        struct DateObject: Codable {
            var value: Date
        }

        let ref = try Firestore
            .firestore()
            .collection("test")
            .document("testConvertTimestampToDate")
        let writeData = TimestampObject()
        try await ref.setData(writeData)
        let readData = try await ref.getDocument(type: DateObject.self)

        #expect(writeData.value.seconds == Int64(readData!.value.timeIntervalSince1970))
    }

    @Test func convertIntToDouble() async throws {

        struct IntObject: Codable {
            var value: Int = 0
        }

        struct DoubleObject: Codable {
            var value: Double = 0
        }

        let ref = try Firestore
            .firestore()
            .collection("test")
            .document("testConvertIntToDouble")
        let writeData = IntObject(value: 5)
        try await ref.setData(writeData)
        let readData = try await ref.getDocument(type: DoubleObject.self)
        #expect(Double(writeData.value) == readData!.value)
    }

    @Test func roundtrip() async throws {
        struct DeepNestObject: Codable, Equatable {
            var number: Int
            var string: String
            var bool: Bool
            var array: [String]
            var map: [String: String]
            var date: Date
            var timestamp: Timestamp
            var geoPoint: GeoPoint
            var reference: DocumentReference
        }

        struct NestObject: Codable, Equatable {
            var number: Int
            var string: String
            var bool: Bool
            var array: [String]
            var map: [String: String]
            var date: Date
            var timestamp: Timestamp
            var geoPoint: GeoPoint
            var reference: DocumentReference
            var nested: DeepNestObject
        }

        struct Object: Codable, Equatable {
            var number: Int
            var string: String
            var bool: Bool
            var array: [String]
            var map: [String: String]
            var date: Date
            var timestamp: Timestamp
            var geoPoint: GeoPoint
            var reference: DocumentReference
            var nested: NestObject
        }

        let writeData: Object = try Object(
            number: 0,
            string: "string",
            bool: true,
            array: ["0", "1"],
            map: ["key": "value"],
            date: Date(timeIntervalSince1970: 0),
            timestamp: Timestamp(seconds: 0, nanos: 0),
            geoPoint: GeoPoint(latitude: 0, longitude: 0),
            reference: Firestore.firestore().document("documents/id"),
            nested: NestObject(
                number: 0,
                string: "string",
                bool: true,
                array: ["0", "1"],
                map: ["key": "value"],
                date: Date(timeIntervalSince1970: 0),
                timestamp: Timestamp(seconds: 0, nanos: 0),
                geoPoint: GeoPoint(latitude: 0, longitude: 0),
                reference: Firestore.firestore().document("documents/id"),
                nested: DeepNestObject(
                    number: 0,
                    string: "string",
                    bool: true,
                    array: ["0", "1"],
                    map: ["key": "value"],
                    date: Date(timeIntervalSince1970: 0),
                    timestamp: Timestamp(seconds: 0, nanos: 0),
                    geoPoint: GeoPoint(latitude: 0, longitude: 0),
                    reference: Firestore.firestore().document("documents/id")
                )
            )
        )

        let ref = try Firestore
            .firestore()
            .collection("test")
            .document("roundtrip")
        try await ref.setData(writeData)
        let readData = try await ref.getDocument(type: Object.self)

        #expect(writeData.number == readData!.number)
        #expect(writeData.string == readData!.string)
        #expect(writeData.bool == readData!.bool)
        #expect(writeData.array == readData!.array)
        #expect(writeData.map == readData!.map)
        #expect(writeData.date == readData!.date)
        #expect(writeData.timestamp == readData!.timestamp)
        #expect(writeData.geoPoint == readData!.geoPoint)
        #expect(writeData.reference == readData!.reference)
        #expect(writeData == readData)
    }
}

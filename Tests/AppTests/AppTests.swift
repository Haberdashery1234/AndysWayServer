import Hummingbird
import HummingbirdTesting
import Logging
import XCTest

@testable import App

final class AppTests: XCTestCase {
    struct TestArguments: AppArguments {
        let hostname = "127.0.0.1"
        let port = 8080
        let logLevel: Logger.Level? = nil
    }

    struct CreateRequest: Encodable {
        let title: String
        let order: Int?
    }
 
    static func create(title: String, order: Int? = nil, client: some TestClientProtocol) async throws -> Marker {
        let request = CreateRequest(title: title, order: order)
        let buffer = try JSONEncoder().encodeAsByteBuffer(request, allocator: ByteBufferAllocator())
        return try await client.execute(uri: "/markers", method: .post, body: buffer) { response in
            XCTAssertEqual(response.status, .created)
            return try JSONDecoder().decode(Marker.self, from: response.body)
        }
    }

    static func get(id: UUID, client: some TestClientProtocol) async throws -> Marker? {
        try await client.execute(uri: "/markers/\(id)", method: .get) { response in
            // either the get request returned an 200 status or it didn't return a Marker
            XCTAssert(response.status == .ok || response.body.readableBytes == 0)
            if response.body.readableBytes > 0 {
                return try JSONDecoder().decode(Marker.self, from: response.body)
            } else {
                return nil
            }
        }
    }

    static func list(client: some TestClientProtocol) async throws -> [Marker] {
        try await client.execute(uri: "/markers", method: .get) { response in
            XCTAssertEqual(response.status, .ok)
            return try JSONDecoder().decode([Marker].self, from: response.body)
        }
    }

    struct UpdateRequest: Encodable {
        let title: String?
        let order: Int?
        let completed: Bool?
    }

    static func patch(id: UUID, title: String? = nil, order: Int? = nil, completed: Bool? = nil, client: some TestClientProtocol) async throws -> Marker? {
        let request = UpdateRequest(title: title, order: order, completed: completed)
        let buffer = try JSONEncoder().encodeAsByteBuffer(request, allocator: ByteBufferAllocator())
        return try await client.execute(uri: "/markers/\(id)", method: .patch, body: buffer) { response in
            XCTAssertEqual(response.status, .ok)
            if response.body.readableBytes > 0 {
                return try JSONDecoder().decode(Marker.self, from: response.body)
            } else {
                return nil
            }
        }
    }

    static func delete(id: UUID, client: some TestClientProtocol) async throws -> HTTPResponse.Status {
        try await client.execute(uri: "/markers/\(id)", method: .delete) { response in
            response.status
        }
    }

    static func deleteAll(client: some TestClientProtocol) async throws {
        try await client.execute(uri: "/markers", method: .delete) { _ in }
    }

    // MARK: Tests

    func testCreate() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            let marker = try await Self.create(title: "My first marker", client: client)
            XCTAssertEqual(marker.title, "My first marker")
        }
    }

    func testPatch() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            // create marker
            let marker = try await Self.create(title: "Deliver parcels to James", client: client)
            // rename it
            _ = try await Self.patch(id: marker.id, title: "Deliver parcels to Claire", client: client)
            let editedMarker = try await Self.get(id: marker.id, client: client)
            XCTAssertEqual(editedMarker?.title, "Deliver parcels to Claire")
            // set it to completed
            _ = try await Self.patch(id: marker.id, completed: true, client: client)
            let editedMarker2 = try await Self.get(id: marker.id, client: client)
            XCTAssertEqual(editedMarker2?.completed, true)
            // revert it
            _ = try await Self.patch(id: marker.id, title: "Deliver parcels to James", completed: false, client: client)
            let editedMarker3 = try await Self.get(id: marker.id, client: client)
            XCTAssertEqual(editedMarker3?.title, "Deliver parcels to James")
            XCTAssertEqual(editedMarker3?.completed, false)
        }
    }

    func testAPI() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            // create two markers
            let marker1 = try await Self.create(title: "Wash my hair", client: client)
            let marker2 = try await Self.create(title: "Brush my teeth", client: client)
            // get first marker
            let getMarker = try await Self.get(id: marker1.id, client: client)
            XCTAssertEqual(getMarker, marker1)
            // patch second marker
            let optionalPatchedMarker = try await Self.patch(id: marker2.id, completed: true, client: client)
            let patchedMarker = try XCTUnwrap(optionalPatchedMarker)
            XCTAssertEqual(patchedMarker.completed, true)
            XCTAssertEqual(patchedMarker.title, marker2.title)
            // get all markers and check first marker and patched second marker are in the list
            let markers = try await Self.list(client: client)
            XCTAssertNotNil(markers.firstIndex(of: marker1))
            XCTAssertNotNil(markers.firstIndex(of: patchedMarker))
            // delete a marker and verify it has been deleted
            let status = try await Self.delete(id: marker1.id, client: client)
            XCTAssertEqual(status, .ok)
            let deletedMarker = try await Self.get(id: marker1.id, client: client)
            XCTAssertNil(deletedMarker)
            // delete all markers and verify there are none left
            try await Self.deleteAll(client: client)
            let markers2 = try await Self.list(client: client)
            XCTAssertEqual(markers2.count, 0)
        }
    }

    func testDeletingMarkerTwiceReturnsBadRequest() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            let marker = try await Self.create(title: "Delete me", client: client)
            let status1 = try await Self.delete(id: marker.id, client: client)
            XCTAssertEqual(status1, .ok)
            let status2 = try await Self.delete(id: marker.id, client: client)
            XCTAssertEqual(status2, .badRequest)
        }
    }

    func testGettingMarkerWithInvalidUUIDReturnsBadRequest() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            // The get helper function doesnt allow me to supply random strings
            return try await client.execute(uri: "/markers/NotAUUID", method: .get) { response in
                XCTAssertEqual(response.status, .badRequest)
            }
        }
    }

    func test30ConcurrentlyCreatedMarkersAreAllCreated() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            let markers = try await withThrowingTaskGroup(of: Marker.self) { group in
                for count in 0..<30 {
                    group.addTask {
                        try await Self.create(title: "Marker: \(count)", client: client)
                    }
                }
                var markers: [Marker] = []
                for try await marker in group {
                    markers.append(marker)
                }
                return markers
            }
            let markerList = try await Self.list(client: client)
            for marker in markers {
                XCTAssertNotNil(markerList.firstIndex(of: marker))
            }
        }
    }

    func testUpdatingNonExistentMarkerReturnsBadRequest() async throws {
        let app = try await buildApplication(TestArguments())
        try await app.test(.router) { client in
            // The patch helper function assumes it is going to work so we have to write our own here
            let request = UpdateRequest(title: "Update", order: nil, completed: nil)
            let buffer = try JSONEncoder().encodeAsByteBuffer(request, allocator: ByteBufferAllocator())
            return try await client.execute(uri: "/markers/\(UUID())", method: .patch, body: buffer) { response in
                XCTAssertEqual(response.status, .badRequest)
            }
        }
    }
}

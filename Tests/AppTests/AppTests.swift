@testable import App
import XCTVapor
import Testing
import Fluent

@Suite("App Tests with DB", .serialized)
struct AppTests {
    private func withApp(_ test: (Application) async throws -> ()) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await app.autoMigrate()   
            try await test(app)
            try await app.autoRevert()   
        }
        catch {
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
    
    @Test("Test Hello World Route")
    func helloWorld() async throws {
        try await withApp { app in
            try await app.test(.GET, "hello", afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.body.string == "Hello, world!")
            })
        }
    }
    
    @Test("Getting all the Markers")
    func getAllMarkers() async throws {
        try await withApp { app in
            let sampleMarkers = [Marker(title: "sample1"), Marker(title: "sample2")]
            try await sampleMarkers.create(on: app.db)
            
            try await app.test(.GET, "markers", afterResponse: { res async throws in
                #expect(res.status == .ok)
                #expect(try res.content.decode([MarkerDTO].self) == sampleMarkers.map { $0.toDTO()} )
            })
        }
    }
    
    @Test("Creating a Marker")
    func createMarker() async throws {
        let newDTO = MarkerDTO(id: nil, title: "test")
        
        try await withApp { app in
            try await app.test(.POST, "markers", beforeRequest: { req in
                try req.content.encode(newDTO)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let models = try await Marker.query(on: app.db).all()
                #expect(models.map({ $0.toDTO().title }) == [newDTO.title])
                XCTAssertEqual(models.map { $0.toDTO() }, [newDTO])
            })
        }
    }
    
    @Test("Deleting a Marker")
    func deleteMarker() async throws {
        let testMarkers = [Marker(title: "test1"), Marker(title: "test2")]
        
        try await withApp { app in
            try await testMarkers.create(on: app.db)
            
            try await app.test(.DELETE, "markers/\(testMarkers[0].requireID())", afterResponse: { res async throws in
                #expect(res.status == .noContent)
                let model = try await Marker.find(testMarkers[0].id, on: app.db)
                #expect(model == nil)
            })
        }
    }
}

extension MarkerDTO: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
    }
}

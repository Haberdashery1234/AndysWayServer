import Fluent
import Vapor

struct MarkerController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let markers = routes.grouped("markers")

        markers.get(use: self.index)
        markers.post(use: self.create)
        markers.group(":markerID") { marker in
            marker.delete(use: self.delete)
        }
    }

    @Sendable
    func index(req: Request) async throws -> [MarkerDTO] {
        try await Marker.query(on: req.db).all().map { $0.toDTO() }
    }

    @Sendable
    func create(req: Request) async throws -> MarkerDTO {
        let marker = try req.content.decode(MarkerDTO.self).toModel()

        try await marker.save(on: req.db)
        return marker.toDTO()
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let marker = try await Marker.find(req.parameters.get("markerID"), on: req.db) else {
            throw Abort(.notFound)
        }

        try await marker.delete(on: req.db)
        return .noContent
    }
}

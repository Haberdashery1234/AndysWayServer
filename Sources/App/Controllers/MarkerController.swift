import FluentKit
import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdFluent
import PostgresNIO

struct MarkerController {
    struct MarkerContext: ChildRequestContext {
        var coreContext: CoreRequestContextStorage

        init(context: AppRequestContext) throws {
            self.coreContext = context.coreContext
        }

        var requestDecoder: MarkerAuthRequestDecoder {
            MarkerAuthRequestDecoder()
        }
    }

    let fluent: Fluent
    let sessionAuthenticator: SessionAuthenticator<AppRequestContext, UserRepository>

    func addRoutes(to group: RouterGroup<AppRequestContext>) {
        group
            .add(middleware: self.sessionAuthenticator)
            .group(context: MarkerContext.self)
            .get(use: self.list)
            .get(":id", use: self.get)
            .post(use: self.create)
            .delete(":id", use: self.deleteId)
    }

   /// Get list of markers entrypoint
    @Sendable func list(_ request: Request, context: MarkerContext) async throws -> [Marker] {
        return try await Marker.query(on: self.fluent.db()).all()
    }

    struct CreateMarkerRequest: ResponseCodable {
        let marker_type: String
        let latitude: Float
        let longitude: Float
        let created_by: UUID
    }

    /// Create marker entrypoint
    @Sendable func create(_ request: Request, context: MarkerContext) async throws -> EditedResponse<Marker> {
        let markerRequest = try await request.decode(as: CreateMarkerRequest.self, context: context)
        guard let _ = request.head.authority else { throw HTTPError(.badRequest, message: "No host header") }
        let marker = Marker(marker_type: markerRequest.marker_type, latitude: markerRequest.latitude, longitude: markerRequest.longitude, created_by: markerRequest.created_by, created_on: Date(), last_updated: Date())
        let db = self.fluent.db()
        _ = try await marker.save(on: db)
        return .init(status: .created, response: marker)
    }

    @Sendable func get(_ request: Request, context: MarkerContext) async throws -> Marker? {
        let id = try context.parameters.require("id", as: UUID.self)
        return try await Marker.query(on: self.fluent.db())
            .filter(\.$id == id)
            .first()
    }

    /// Delete marker entrypoint
    @Sendable func deleteId(_ request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
        let id = try context.parameters.require("id", as: UUID.self)
        let db = self.fluent.db()
        guard let marker = try await Marker.query(on: db)
            .filter(\.$id == id)
            .first()
        else {
            throw HTTPError(.notFound)
        }

        try await marker.delete(on: db)
        return .ok
    }
}

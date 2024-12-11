import Foundation
import Hummingbird

struct MarkerController<Repository: MarkerRepository> {
    // Marker repository
    let repository: Repository

    // return marker endpoints
    var endpoints: RouteCollection<AppRequestContext> {
        return RouteCollection(context: AppRequestContext.self)
            .get(":id", use: self.get)
            .get(use: self.list)
            .post(use: self.create)
            .patch(":id", use: self.update)
            .delete(":id", use: self.delete)
            .delete(use: self.deleteAll)
    }

    /// Delete all markers entrypoint
    @Sendable func deleteAll(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
        try await self.repository.deleteAll()
        return .ok
    }

    /// Delete marker entrypoint
    @Sendable func delete(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
        let id = try context.parameters.require("id", as: UUID.self)
        if try await self.repository.delete(id: id) {
            return .ok
        } else {
            return .badRequest
        }
    }

    struct CreateRequest: Decodable {
        let marker_type: String
        let latitude: Float
        let longitude: Float
        let created_by: UUID
    }

    /// Create marker entrypoint
    @Sendable func create(request: Request, context: some RequestContext) async throws -> EditedResponse<Marker> {
        let request = try await request.decode(as: CreateRequest.self, context: context)
        let marker = try await self.repository.create(marker_type: Marker_Type(rawValue: request.marker_type)!, latitude: request.latitude, longitude: request.longitude, created_by: request.created_by)
        return EditedResponse(status: .created, response: marker)
    }

    struct UpdateRequest: Decodable {
        let marker_type: String?
        let latitude: Float?
        let longitude: Float?
    }

    /// Update marker entrypoint
    @Sendable func update(request: Request, context: some RequestContext) async throws -> Marker? {
        let id = try context.parameters.require("id", as: UUID.self)
        let request = try await request.decode(as: UpdateRequest.self, context: context)
        guard let marker = try await self.repository.update(
            id: id,
            marker_type: Marker_Type(rawValue: request.marker_type!) ?? nil,
            latitude: request.latitude,
            longitude: request.longitude
        ) else {
            throw HTTPError(.badRequest)
        }
        return marker
    }

    /// Get marker entrypoint
    @Sendable func get(request: Request, context: some RequestContext) async throws -> Marker? {
        let id = try context.parameters.require("id", as: UUID.self)
        return try await self.repository.get(id: id)
    }

    /// Get list of markers entrypoint
    @Sendable func list(request: Request, context: some RequestContext) async throws -> [Marker] {
        return try await self.repository.list()
    }
}

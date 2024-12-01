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

    struct UpdateRequest: Decodable {
        let title: String?
        let order: Int?
        let completed: Bool?
    }

    /// Update marker entrypoint
    @Sendable func update(request: Request, context: some RequestContext) async throws -> Marker? {
        let id = try context.parameters.require("id", as: UUID.self)
        let request = try await request.decode(as: UpdateRequest.self, context: context)
        guard let marker = try await self.repository.update(
            id: id,
            title: request.title,
            order: request.order,
            completed: request.completed
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

    struct CreateRequest: Decodable {
        let title: String
        let order: Int?
    }

    /// Create marker entrypoint
    @Sendable func create(request: Request, context: some RequestContext) async throws -> EditedResponse<Marker> {
        let request = try await request.decode(as: CreateRequest.self, context: context)
        let marker = try await self.repository.create(title: request.title, order: request.order, urlPrefix: "http://localhost:8080/markers/")
        return EditedResponse(status: .created, response: marker)
    }
}

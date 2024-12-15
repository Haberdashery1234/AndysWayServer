import FluentKit

struct CreateMarker: AsyncMigration {
    func prepare(on database: Database) async throws {
        return try await database.schema("markers")
            .id()
            .field("marker_type", .string, .required)
            .field("latitude", .float, .required)
            .field("longitude", .float, .required)
            .field("created_by", .uuid, .required, .references("users", "id"))
            .field("created_on", .time, .required)
            .field("last_updated", .time, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        return try await database.schema("markers").delete()
    }
}

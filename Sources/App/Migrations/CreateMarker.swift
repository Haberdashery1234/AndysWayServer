import Fluent

struct CreateMarker: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("markers")
            .id()
            .field("title", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("markers").delete()
    }
}

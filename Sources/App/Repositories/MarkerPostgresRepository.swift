import Foundation
import Hummingbird
import PostgresNIO

struct MarkerPostgresRepository: MarkerRepository, Sendable {
    let client: PostgresClient
    let logger: Logger

    /// Create Markers table
    func createTable() async throws {
        try await self.client.query(
            """
            CREATE TABLE IF NOT EXISTS markers (
                "id" uuid PRIMARY KEY,
                "title" text NOT NULL,
                "order" integer,
                "completed" boolean,
                "url" text
            )
            """,
            logger: self.logger
        )
    }

    /// Create markers.
    func create(title: String, order: Int?, urlPrefix: String) async throws -> Marker {
        let id = UUID()
        let url = urlPrefix + id.uuidString
        // The string interpolation is building a PostgresQuery with bindings and is safe from sql injection
        try await self.client.query(
            "INSERT INTO markers (id, title, url, \"order\") VALUES (\(id), \(title), \(url), \(order));",
            logger: self.logger
        )
        return Marker(id: id, title: title, order: order, url: url, completed: nil)
    }

    /// Get marker.
    func get(id: UUID) async throws -> Marker? {
        // The string interpolation is building a PostgresQuery with bindings and is safe from sql injection
        let stream = try await self.client.query(
            """
            SELECT "id", "title", "order", "url", "completed" FROM markers WHERE "id" = \(id)
            """,
            logger: self.logger
        )
        for try await(id, title, order, url, completed) in stream.decode((UUID, String, Int?, String, Bool?).self, context: .default) {
            return Marker(id: id, title: title, order: order, url: url, completed: completed)
        }
        return nil
    }

    /// List all markers
    func list() async throws -> [Marker] {
        let stream = try await self.client.query(
            """
            SELECT "id", "title", "order", "url", "completed" FROM markers
            """,
            logger: self.logger
        )
        var markers: [Marker] = []
        for try await(id, title, order, url, completed) in stream.decode((UUID, String, Int?, String, Bool?).self, context: .default) {
            let marker = Marker(id: id, title: title, order: order, url: url, completed: completed)
            markers.append(marker)
        }
        return markers
    }

    /// Update marker. Returns updated marker if successful
    func update(id: UUID, title: String?, order: Int?, completed: Bool?) async throws -> Marker? {
        let query: PostgresQuery?
        // UPDATE query. Work out query based on whick values are not nil
        // The string interpolation is building a PostgresQuery with bindings and is safe from sql injection
        if let title {
            if let order {
                if let completed {
                    query = "UPDATE markers SET title = \(title), order = \(order), completed = \(completed) WHERE id = \(id)"
                } else {
                    query = "UPDATE markers SET title = \(title), order = \(order) WHERE id = \(id)"
                }
            } else {
                if let completed {
                    query = "UPDATE markers SET title = \(title), completed = \(completed) WHERE id = \(id)"
                } else {
                    query = "UPDATE markers SET title = \(title) WHERE id = \(id)"
                }
            }
        } else {
            if let order {
                if let completed {
                    query = "UPDATE markers SET order = \(order), completed = \(completed) WHERE id = \(id)"
                } else {
                    query = "UPDATE markers SET order = \(order) WHERE id = \(id)"
                }
            } else {
                if let completed {
                    query = "UPDATE markers SET completed = \(completed) WHERE id = \(id)"
                } else {
                    query = nil
                }
            }
        }
        if let query {
            _ = try await self.client.query(query, logger: self.logger)
        }

        // SELECT so I can get the full details of the Marker back
        // The string interpolation is building a PostgresQuery with bindings and is safe from sql injection
        let stream = try await self.client.query(
            """
            SELECT "id", "title", "order", "url", "completed" FROM markers WHERE "id" = \(id)
            """,
            logger: self.logger
        )
        for try await(id, title, order, url, completed) in stream.decode((UUID, String, Int?, String, Bool?).self, context: .default) {
            return Marker(id: id, title: title, order: order, url: url, completed: completed)
        }
        return nil
    }

    /// Delete marker. Returns true if successful
    func delete(id: UUID) async throws -> Bool {
        // The string interpolation is building a PostgresQuery with bindings and is safe from sql injection
        let selectStream = try await self.client.query(
            """
            SELECT "id" FROM markers WHERE "id" = \(id)
            """,
            logger: self.logger
        )
        // if we didn't find the item with this id then return false
        if try await selectStream.decode(UUID.self, context: .default).first(where: { _ in true }) == nil {
            return false
        }
        _ = try await self.client.query("DELETE FROM markers WHERE id = \(id);", logger: self.logger)
        return true
    }

    /// Delete all markers
    func deleteAll() async throws {
        try await self.client.query("DELETE FROM markers;", logger: self.logger)
    }
}

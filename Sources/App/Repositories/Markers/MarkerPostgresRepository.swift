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
                "marker_type" text NOT NULL,
                "latitude" float,
                "longitude" float
            )
            """,
            logger: self.logger
        )
    }

    /// Create marker.
    func create(marker_type: Marker_Type, latitude: Float, longitude: Float) async throws -> Marker {
        let id = UUID()
        // The string interpolation is building a PostgresQuery with bindings and is safe from sql injection
        do {
            try await self.client.query(
                "INSERT INTO markers (marker_id, marker_type, latitude, longitude, created_at) VALUES (\(id), \(marker_type.rawValue), \(latitude), \(longitude), \(Date.now));",
                logger: self.logger
            ) 
        } catch {
            logger.error("\(String(reflecting: error))")
        }
        return Marker(id: id, marker_type: marker_type, latitude: latitude, longitude: longitude)
    }

    /// Get marker.
    func get(id: UUID) async throws -> Marker? {
        // The string interpolation is building a PostgresQuery with bindings and is safe from sql injection
        let stream = try await self.client.query(
            """
            SELECT * FROM markers WHERE "id" = \(id)
            """,
            logger: self.logger
        )
        do {
            for try await(id, marker_type, latitude, longitude) in stream.decode((UUID, String, Float, Float).self, context: .default) {
                return Marker(id: id, marker_type: Marker_Type(rawValue: marker_type)!, latitude: latitude, longitude: longitude)
            }
        } catch {
            logger.error("\(String(reflecting: error))")
        }
        return nil
    }

    /// List all markers
    func list() async throws -> [Marker] {
        let stream = try await self.client.query(
            """
            SELECT * FROM markers
            """,
            logger: self.logger
        )
        var markers: [Marker] = []
        do {
            for try await(id, marker_type, latitude, longitude) in stream.decode((UUID, String, Float, Float).self, context: .default) {
                let marker = Marker(id: id, marker_type: Marker_Type(rawValue: marker_type)!, latitude: latitude, longitude: longitude)
                markers.append(marker)
            }
        } catch {
            logger.error("\(String(reflecting: error))")
        }
        return markers
    }

    /// Update marker. Returns updated marker if successful
    func update(id: UUID, marker_type: Marker_Type?, latitude: Float?, longitude: Float?) async throws -> Marker? {
        let query: PostgresQuery?
        // UPDATE query. Work out query based on whick values are not nil
        // The string interpolation is building a PostgresQuery with bindings and is safe from sql injection
        if let marker_type {
            if let latitude {
                if let longitude {
                    query = "UPDATE markers SET marker_type = \(marker_type.rawValue), latitude = \(latitude), longitude = \(longitude) WHERE id = \(id)"
                } else {
                    query = "UPDATE markers SET marker_type = \(marker_type.rawValue), latitude = \(latitude) WHERE id = \(id)"
                }
            } else {
                if let longitude {
                    query = "UPDATE markers SET marker_type = \(marker_type.rawValue), longitude = \(longitude) WHERE id = \(id)"
                } else {
                    query = "UPDATE markers SET marker_type = \(marker_type.rawValue) WHERE id = \(id)"
                }
            }
        } else {
            if let latitude {
                if let longitude {
                    query = "UPDATE markers SET latitude = \(latitude), longitude = \(longitude) WHERE id = \(id)"
                } else {
                    query = "UPDATE markers SET latitude = \(latitude) WHERE id = \(id)"
                }
            } else {
                if let longitude {
                    query = "UPDATE markers SET longitude = \(longitude) WHERE id = \(id)"
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
        for try await(id, marker_type, latitude, longitude) in stream.decode((UUID, String, Float, Float).self, context: .default) {
            return Marker(id: id, marker_type: Marker_Type(rawValue: marker_type)!, latitude: latitude, longitude: longitude)
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

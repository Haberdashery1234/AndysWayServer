import Foundation
import Hummingbird
import PostgresNIO

struct UserPostgresRepository: UserRepository, Sendable {
    let client: PostgresClient
    let logger: Logger

    /// Create Markers table
    func createTable() async throws {
        try await self.client.query(
            """
            CREATE TABLE IF NOT EXISTS users (
                "user_id" uuid PRIMARY KEY,
                "password" bpchar(1) NOT NULL,
                "email" bpchar(1) NOT NULL,
                "display_name" bpchar(1) NOT NULL,
                "city" bpchar(1),
                "state" bpchar(1),
                "created_on" timestamp,
                "last_login" timestamp,
            )
            """,
            logger: self.logger
        )
    }

    /// Create marker.
    func create(id: UUID, email: String, display_name: String, location_city: String, location_state: String, location_country: String) async throws -> User {
        let id = UUID()
        let creation_date = Date.now
        // The string interpolation is building a PostgresQuery with bindings and is safe from sql injection
        do {
            try await self.client.query(
                """
                INSERT INTO markers
                    (user_id, email, display_name, location_city, location_state, location_country, created_on)
                VALUES 
                    (\(id), \(email), \(display_name), \(location_city), \(location_state), \(location_country), \(creation_date));
                """,
                logger: self.logger
            ) 
        } catch {
            logger.error("\(String(reflecting: error))")
        }
        return User(id: id, email: email, display_name: display_name, location_city: location_city, location_state: location_state, location_country: location_country, created_on: creation_date)
    }

    /// Get marker.
    func get(id: UUID) async throws -> User? {
        // The string interpolation is building a PostgresQuery with bindings and is safe from sql injection
        let stream = try await self.client.query(
            """
            SELECT * FROM markers WHERE "id" = \(id)
            """,
            logger: self.logger
        )
        do {
            for try await(id, email, display_name, location_city, location_state, location_country, created_on, last_login) in stream.decode((UUID, String, String, String, String, String, Date, Date).self, context: .default) {
                return User(id: id, email: email, display_name: display_name, location_city: location_city, location_state: location_state, location_country: location_country, created_on: created_on, last_login: last_login)
            }
        } catch {
            logger.error("\(String(reflecting: error))")
        }
        return nil
    }

    /// Update marker. Returns updated marker if successful
    func update(id: UUID, email: String?, display_name: String?, location_city: String?, location_state: String?, location_country: String?) async throws -> User? {
        var query: PostgresQuery? = nil
        var queries: Array<String> = []
        // UPDATE query. Work out query based on whick values are not nil
        // The string interpolation is building a PostgresQuery with bindings and is safe from sql injection
        if let email { queries.append("email = \(email)") }
        if let display_name { queries.append("display_name = \(display_name)") }
        if let location_city { queries.append("location_city = \(location_city)") }
        if let location_state { queries.append("location_state = \(location_state)") }
        if let location_country { queries.append("location_country = \(location_country)") }
        
        if queries.count > 0 {
            query = "UPDATE users SET \(queries.joined(separator: ", ")) WHERE id = \(id)"
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
        for try await(id, email, display_name, location_city, location_state, location_country, created_on) in stream.decode((UUID, String, String, String, String, String, Date).self, context: .default) {
            return User(id: id, email: email, display_name: display_name, location_city: location_city, location_state: location_state, location_country: location_country, created_on: created_on)
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
}

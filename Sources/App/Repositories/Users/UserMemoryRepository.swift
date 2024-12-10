import Foundation

/// Concrete implementation of `MarkerRepository` that stores everything in memory
actor UserMemoryRepository: UserRepository {
    var users: [UUID: User]

    init() {
        self.users = [:]
    }

    /// Create marker.
    func create(id: UUID, email: String, display_name: String, location_city: String, location_state: String, location_country: String) async throws -> User {
        let id = UUID()
        let user = User(id: id, email: email, display_name: display_name, location_city: location_city, location_state: location_state, location_country: location_country, created_on: Date.now)
        self.users[id] = user
        return user
    }

    /// Get marker
    func get(id: UUID) async throws -> User? {
        return self.users[id]
    }

    /// Update marker. Returns updated marker if successful
    func update(id: UUID, email: String?, display_name: String?, location_city: String?, location_state: String?, location_country: String?) async throws -> User? {
        if var user = self.users[id] {
            if let email {
                user.email = email
            }
            if let display_name {
                user.display_name = display_name
            }
            if let location_city {
                user.location_city = location_city
            }
            if let location_state {
                user.location_state = location_state
            }
            if let location_country {
                user.location_country = location_country
            }
            self.users[id] = user
            return user
        }
        return nil
    }

    /// Delete marker. Returns true if successful
    func delete(id: UUID) async throws -> Bool {
        if self.users[id] != nil {
            self.users[id] = nil
            return true
        }
        return false
    }
}

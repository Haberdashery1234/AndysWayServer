import Foundation

protocol UserRepository: Sendable {
    func create(id: UUID, email: String, display_name: String, location_city: String, location_state: String, location_country: String) async throws -> User
    func get(id: UUID) async throws -> User?
    func update(id: UUID, email: String?, display_name: String?, location_city: String?, location_state: String?, location_country: String?) async throws -> User?
    func delete(id: UUID) async throws -> Bool
}

import Foundation

/// Interface for storing and editing markers
protocol MarkerRepository: Sendable {
    /// Create marker.
    func create(title: String, order: Int?, urlPrefix: String) async throws -> Marker
    /// Get marker
    func get(id: UUID) async throws -> Marker?
    /// List all markers
    func list() async throws -> [Marker]
    /// Update marker. Returns updated marker if successful
    func update(id: UUID, title: String?, order: Int?, completed: Bool?) async throws -> Marker?
    /// Delete marker. Returns true if successful
    func delete(id: UUID) async throws -> Bool
    /// Delete all markers
    func deleteAll() async throws
}

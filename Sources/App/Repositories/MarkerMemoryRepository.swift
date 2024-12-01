import Foundation

/// Concrete implementation of `MarkerRepository` that stores everything in memory
actor MarkerMemoryRepository: MarkerRepository {
    var markers: [UUID: Marker]

    init() {
        self.markers = [:]
    }

    /// Create marker.
    func create(title: String, order: Int?, urlPrefix: String) async throws -> Marker {
        let id = UUID()
        let url = urlPrefix + id.uuidString
        let marker = Marker(id: id, title: title, order: order, url: url, completed: false)
        self.markers[id] = marker
        return marker
    }

    /// Get marker
    func get(id: UUID) async throws -> Marker? {
        return self.markers[id]
    }

    /// List all markers
    func list() async throws -> [Marker] {
        return self.markers.values.map { $0 }
    }

    /// Update marker. Returns updated marker if successful
    func update(id: UUID, title: String?, order: Int?, completed: Bool?) async throws -> Marker? {
        if var marker = self.markers[id] {
            if let title {
                marker.title = title
            }
            if let order {
                marker.order = order
            }
            if let completed {
                marker.completed = completed
            }
            self.markers[id] = marker
            return marker
        }
        return nil
    }

    /// Delete marker. Returns true if successful
    func delete(id: UUID) async throws -> Bool {
        if self.markers[id] != nil {
            self.markers[id] = nil
            return true
        }
        return false
    }

    /// Delete all markers
    func deleteAll() async throws {
        self.markers = [:]
    }
}

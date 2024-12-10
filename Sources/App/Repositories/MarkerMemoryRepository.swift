import Foundation

/// Concrete implementation of `MarkerRepository` that stores everything in memory
actor MarkerMemoryRepository: MarkerRepository {
    var markers: [UUID: Marker]

    init() {
        self.markers = [:]
    }

    /// Create marker.
    func create(marker_type: Marker_Type, latitude: Float, longitude: Float) async throws -> Marker {
        let id = UUID()
        let marker = Marker(id: id, marker_type: marker_type, latitude: latitude, longitude: longitude)
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
    func update(id: UUID, marker_type: Marker_Type?, latitude: Float?, longitude: Float?) async throws -> Marker? {
        if var marker = self.markers[id] {
            if let marker_type {
                marker.marker_type = marker_type
            }
            if let latitude {
                marker.latitude = latitude
            }
            if let longitude {
                marker.longitude = longitude
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

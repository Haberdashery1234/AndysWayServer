import Foundation
import Hummingbird

enum Marker_Type: String, Codable, Identifiable, CaseIterable {
    case water = "water"
    case trash = "trash"
    case light = "light"
    case attack = "attack"
    
    var id: RawValue { rawValue }
}


struct Marker {
    // Marker ID
    var id: UUID
    // Marker type
    var marker_type: Marker_Type
    // Marker Latitude
    var latitude: Float
    // Marker Longitude
    var longitude: Float
}

extension Marker: ResponseEncodable, Decodable, Equatable {}

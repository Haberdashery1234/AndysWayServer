import Foundation
import Hummingbird

struct Marker {
    // Marker ID
    var id: UUID
    // Title
    var title: String
    // Order number
    var order: Int?
    // URL to get this Marker
    var url: String
    // Is Marker complete
    var completed: Bool?
}

extension Marker: ResponseEncodable, Decodable, Equatable {}

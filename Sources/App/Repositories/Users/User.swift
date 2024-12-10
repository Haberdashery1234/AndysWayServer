import Foundation
import Hummingbird

struct User {
    var id: UUID
    var email: String
    var display_name: String
    var location_city: String
    var location_state: String
    var location_country: String
    var created_on: Date
    var last_login: Date?
}

extension User: ResponseEncodable, Decodable, Equatable {}

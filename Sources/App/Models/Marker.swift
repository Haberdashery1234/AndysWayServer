import Fluent
import Vapor
import struct Foundation.UUID

/// Property wrappers interact poorly with `Sendable` checking, causing a warning for the `@ID` property
/// It is recommended you write your model with sendability checking on and then suppress the warning
/// afterwards with `@unchecked Sendable`.

final class Coordinates: Fields, @unchecked Sendable {
    @Field(key: "latitude")
    var latitude: Float
    
    @Field(key: "longitude")
    var longitude: Float
    
    // Initialization
    init() { }
}

final class Marker: Model, Content, @unchecked Sendable {
    static let schema = "markers"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "marker_type")
    var marker_type: String

    @Group(key: "coordinates")
    let coordinates: Coordinates
    
    init() { }

    init(id: UUID? = nil, marker_type: String, coordinates: Coordinates) {
        self.id = id
        self.marker_type = marker_type
        self.coordinates = coordinates
    }
    
    func toDTO() -> MarkerDTO {
        .init(
            id: self.id,
            marker_type: self.$marker_type.value
        )
    }
}

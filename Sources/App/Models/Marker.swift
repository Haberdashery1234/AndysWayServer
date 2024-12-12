import FluentKit
import Foundation
import Hummingbird

final class Marker: @unchecked Sendable, Model, ResponseCodable {
    static let schema = "markers"

    @ID(key:.id)
    var id: UUID?

    @Field(key: "marker_type")
    var marker_type: String

    @Field(key: "latitude")
    var latitude: Float

    @Field(key: "longitude")
    var longitude: Float

    @Field(key: "created_by")
    var created_by: UUID

    init() {}

    init(id: UUID? = nil, marker_type: String, latitude: Float, longitude: Float, created_by: UUID) {
        self.id = id
        self.marker_type = marker_type
        self.latitude = latitude
        self.longitude = longitude
        self.created_by = created_by
    }
}

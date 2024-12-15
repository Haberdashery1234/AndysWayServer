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

    @Field(key: "created_on")
    var created_on: Date

    @Field(key: "last_updated")
    var last_updated: Date

    init() {}

    init(id: UUID? = nil, marker_type: String, latitude: Float, longitude: Float, created_by: UUID, created_on: Date, last_updated: Date) {
        self.id = id
        self.marker_type = marker_type
        self.latitude = latitude
        self.longitude = longitude
        self.created_by = created_by
        self.created_on = created_on
        self.last_updated = last_updated
    }
}

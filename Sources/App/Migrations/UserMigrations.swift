import FluentKit

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("user")
            .id()
            .field("display_name", .string, .required)
            .field("email", .string, .required)
            .field("password", .string)
            .field("location_city", .string)
            .field("location_state", .string)
            .field("location_country", .string)
            .field("created_on", .time, .required)
            .field("last_login", .time)
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("user").delete()
    }
}
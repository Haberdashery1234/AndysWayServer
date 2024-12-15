import FluentKit
import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdBasicAuth
import HummingbirdBcrypt
import HummingbirdFluent
import NIOPosix

/// Database description of a user
final class User: Model, PasswordAuthenticatable, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String

    @Field(key: "display_name")
    var display_name: String

    @Field(key: "password")
    var passwordHash: String?

    @Field(key: "location_city")
    var location_city: String?

    @Field(key: "location_state")
    var location_state: String?

    @Field(key: "location_country")
    var location_country: String?

    @Field(key: "created_on")
    var created_on: Date

    init() {}

    init(id: UUID? = nil, display_name: String, email: String, passwordHash: String, location_city: String?, location_state: String?, location_country: String?, created_on: Date) {
        self.id = id
        self.display_name = display_name
        self.email = email
        self.passwordHash = passwordHash
        self.location_city = location_city
        self.location_state = location_state
        self.location_country = location_country
        self.created_on = created_on
    }
}

extension User {
    var username: String { self.display_name }

    /// create a User in the db attached to request
    static func create(display_name: String, email: String, password: String, location_city: String?, location_state: String?, location_country: String?, created_on: Date, db: Database) async throws -> User {
        // check if user exists and if they don't then add new user
        let existingUser = try await User.query(on: db)
            .filter(\.$email == email)
            .first()
        // if user already exist throw conflict
        guard existingUser == nil else { throw HTTPError(.conflict) }

        // Encrypt password on a separate thread
        let passwordHash = try await NIOThreadPool.singleton.runIfActive { Bcrypt.hash(password, cost: 12) }
        // Create user and save to database
        let user = User(display_name: display_name, email: email, passwordHash: passwordHash, location_city: location_city, location_state: location_state, location_country: location_country, created_on: created_on)
        try await user.save(on: db)
        return user
    }

    /// Check user can login
    static func login(email: String, password: String, db: Database) async throws -> User? {
        // check if user exists in the database and then verify the entered password
        // against the one stored in the database. If it is correct then login in user
        let user = try await User.query(on: db)
            .filter(\.$email == email)
            .first()
        guard let user = user else { return nil }
        guard let passwordHash = user.passwordHash else { return nil }
        // Verify the password against the hash stored in the database
        let verified = try await NIOThreadPool.singleton.runIfActive { Bcrypt.verify(password, hash: passwordHash) }
        guard verified else { return nil }
        return user
    }
}

/// Create user request object decoded from HTTP body
struct CreateUserRequest: Decodable {
    let display_name: String
    let email: String
    let password: String
    let location_city: String?
    let location_state: String?
    let location_country: String?
    let created_on: Date

    init(display_name: String, email: String, password: String, location_city: String?, location_state: String?, location_country: String?, created_on: Date) {
        self.display_name = display_name
        self.email = email
        self.password = password
        self.location_city = location_city
        self.location_state = location_state
        self.location_country = location_country
        self.created_on = created_on
    }
}

/// User encoded into HTTP response
struct UserResponse: ResponseCodable {
    let id: UUID?
    let display_name: String
    let email: String
    let location_city: String?
    let location_state: String?
    let location_country: String?
    let created_on: Date

    init(id: UUID?, display_name: String, email: String, location_city: String?, location_state: String?, location_country: String?, created_on: Date) {
        self.id = id
        self.display_name = display_name
        self.email = email
        self.location_city = location_city
        self.location_state = location_state
        self.location_country = location_country
        self.created_on = created_on
    }

    init(from user: User) {
        self.id = user.id
        self.display_name = user.display_name
        self.email = user.email
        self.location_city = user.location_city
        self.location_state = user.location_state
        self.location_country = user.location_country
        self.created_on = user.created_on
    }
}

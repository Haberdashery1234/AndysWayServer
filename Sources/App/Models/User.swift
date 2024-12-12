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
    static let schema = "user"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String

    @Field(key: "name")
    var name: String

    @Field(key: "password")
    var passwordHash: String?

    init() {}

    init(id: UUID? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
}

extension User {
    var username: String { self.name }

    /// create a User in the db attached to request
    static func create(name: String, email: String, password: String, db: Database) async throws -> User {
        // check if user exists and if they don't then add new user
        let existingUser = try await User.query(on: db)
            .filter(\.$email == email)
            .first()
        // if user already exist throw conflict
        guard existingUser == nil else { throw HTTPError(.conflict) }

        // Encrypt password on a separate thread
        let passwordHash = try await NIOThreadPool.singleton.runIfActive { Bcrypt.hash(password, cost: 12) }
        // Create user and save to database
        let user = User(name: name, email: email, passwordHash: passwordHash)
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
    let name: String
    let email: String
    let password: String

    init(name: String, email: String, password: String) {
        self.name = name
        self.email = email
        self.password = password
    }
}

/// User encoded into HTTP response
struct UserResponse: ResponseCodable {
    let id: UUID?

    init(id: UUID?) {
        self.id = id
    }

    init(from user: User) {
        self.id = user.id
    }
}

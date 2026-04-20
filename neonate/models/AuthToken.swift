import Foundation

struct AuthToken: Codable {

    let accessToken: String

    let refreshToken: String

    let tokenType: String

    let expiresIn: TimeInterval

    let issuedAt: Date

    init(
        accessToken: String,
        refreshToken: String,
        tokenType: String = "Bearer",
        expiresIn: TimeInterval = 3600,
        issuedAt: Date = Date()
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.issuedAt = issuedAt
    }

    var expirationDate: Date {
        issuedAt.addingTimeInterval(expiresIn)
    }

    var isExpired: Bool {
        Date() > expirationDate
    }

    var needsRefresh: Bool {
        let timeRemaining = expirationDate.timeIntervalSinceNow
        return timeRemaining < 300
    }

    var remainingTime: TimeInterval {
        max(0, expirationDate.timeIntervalSinceNow)
    }

    func authorizationHeader() -> String {
        "\(tokenType) \(accessToken)"
    }
}

extension AuthToken: Equatable {
    static func == (lhs: AuthToken, rhs: AuthToken) -> Bool {
        lhs.accessToken == rhs.accessToken && lhs.refreshToken == rhs.refreshToken
    }
}

struct AuthResponse: Codable {

    let user: User

    let tokens: AuthToken

    let message: String?

    init(user: User, tokens: AuthToken, message: String? = nil) {
        self.user = user
        self.tokens = tokens
        self.message = message
    }
}

struct RefreshTokenResponse: Codable {

    let accessToken: String

    let refreshToken: String?

    let tokenType: String

    let expiresIn: TimeInterval

    init(
        accessToken: String,
        refreshToken: String? = nil,
        tokenType: String = "Bearer",
        expiresIn: TimeInterval = 3600
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
    }

    func toAuthToken(withOldRefreshToken oldRefreshToken: String? = nil) -> AuthToken {
        AuthToken(
            accessToken: accessToken,
            refreshToken: refreshToken ?? oldRefreshToken ?? "",
            tokenType: tokenType,
            expiresIn: expiresIn,
            issuedAt: Date()
        )
    }
}

#if DEBUG
extension AuthToken {

    static var preview: AuthToken {
        AuthToken(
            accessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
            refreshToken: "refresh_token_example_12345",
            expiresIn: 3600
        )
    }

    static var expiredPreview: AuthToken {
        AuthToken(
            accessToken: "expired_token",
            refreshToken: "refresh_token",
            expiresIn: 3600,
            issuedAt: Date().addingTimeInterval(-7200)
        )
    }
}
#endif

import Foundation
import CryptoKit

class JWTService {

    static let shared = JWTService()

    private init() {}

    private let secretKey = "neonate_secret_key_2025_baby_care_tracker"

    struct JWTHeader: Codable {
        let alg: String
        let typ: String

        static var `default`: JWTHeader {
            JWTHeader(alg: "HS256", typ: "JWT")
        }
    }

    struct JWTPayload: Codable {
        let sub: String
        let username: String
        let email: String
        let iat: TimeInterval
        let exp: TimeInterval
        let type: TokenType

        enum TokenType: String, Codable {
            case access
            case refresh
        }
    }

    struct JWTToken {
        let header: JWTHeader
        let payload: JWTPayload
        let signature: String

        var token: String {
            let headerString = JWTService.encodeToBase64URL(header)
            let payloadString = JWTService.encodeToBase64URL(payload)
            return "\(headerString).\(payloadString).\(signature)"
        }
    }

    func generateAccessToken(
        userId: UUID,
        username: String,
        email: String,
        expiresIn: TimeInterval = 3600
    ) -> String {
        let now = Date().timeIntervalSince1970
        let payload = JWTPayload(
            sub: userId.uuidString,
            username: username,
            email: email,
            iat: now,
            exp: now + expiresIn,
            type: .access
        )

        return generateToken(payload: payload)
    }

    func generateRefreshToken(
        userId: UUID,
        username: String,
        email: String,
        expiresIn: TimeInterval = 2592000
    ) -> String {
        let now = Date().timeIntervalSince1970
        let payload = JWTPayload(
            sub: userId.uuidString,
            username: username,
            email: email,
            iat: now,
            exp: now + expiresIn,
            type: .refresh
        )

        return generateToken(payload: payload)
    }

    func generateTokenPair(userId: UUID, username: String, email: String) -> AuthToken {
        let accessToken = generateAccessToken(userId: userId, username: username, email: email)
        let refreshToken = generateRefreshToken(userId: userId, username: username, email: email)

        return AuthToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenType: "Bearer",
            expiresIn: 3600,
            issuedAt: Date()
        )
    }

    func validateToken(_ token: String) -> JWTPayload? {
        guard let decoded = decodeToken(token) else {
            return nil
        }

        guard verifySignature(token: token, expectedSignature: decoded.signature) else {
            return nil
        }

        let now = Date().timeIntervalSince1970
        guard decoded.payload.exp > now else {
            return nil
        }

        return decoded.payload
    }

    func isTokenExpired(_ token: String) -> Bool {
        guard let payload = decodePayload(from: token) else {
            return true
        }

        let now = Date().timeIntervalSince1970
        return payload.exp <= now
    }

    func getPayload(from token: String) -> JWTPayload? {
        return decodePayload(from: token)
    }

    func getExpirationDate(from token: String) -> Date? {
        guard let payload = decodePayload(from: token) else {
            return nil
        }
        return Date(timeIntervalSince1970: payload.exp)
    }

    func getRemainingTime(from token: String) -> TimeInterval? {
        guard let expirationDate = getExpirationDate(from: token) else {
            return nil
        }
        return max(0, expirationDate.timeIntervalSinceNow)
    }

    private func generateToken(payload: JWTPayload) -> String {
        let header = JWTHeader.default

        let headerString = Self.encodeToBase64URL(header)
        let payloadString = Self.encodeToBase64URL(payload)
        let dataToSign = "\(headerString).\(payloadString)"

        let signature = createSignature(for: dataToSign)

        return "\(dataToSign).\(signature)"
    }

    private func createSignature(for data: String) -> String {
        let key = SymmetricKey(data: secretKey.data(using: .utf8)!)
        let dataToSign = data.data(using: .utf8)!

        let signature = HMAC<SHA256>.authenticationCode(for: dataToSign, using: key)
        return Data(signature).base64URLEncodedString()
    }

    private func verifySignature(token: String, expectedSignature: String) -> Bool {
        let components = token.split(separator: ".").map(String.init)
        guard components.count == 3 else { return false }

        let dataToSign = "\(components[0]).\(components[1])"
        let actualSignature = createSignature(for: dataToSign)

        return actualSignature == expectedSignature
    }

    private func decodeToken(_ token: String) -> (header: JWTHeader, payload: JWTPayload, signature: String)? {
        let components = token.split(separator: ".").map(String.init)
        guard components.count == 3 else {
            return nil
        }

        guard let header = decodeFromBase64URL(components[0], as: JWTHeader.self),
              let payload = decodeFromBase64URL(components[1], as: JWTPayload.self) else {
            return nil
        }

        return (header, payload, components[2])
    }

    private func decodePayload(from token: String) -> JWTPayload? {
        let components = token.split(separator: ".").map(String.init)
        guard components.count == 3 else {
            return nil
        }

        return decodeFromBase64URL(components[1], as: JWTPayload.self)
    }

    private static func encodeToBase64URL<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(value) else {
            return ""
        }
        return data.base64URLEncodedString()
    }

    private func decodeFromBase64URL<T: Decodable>(_ string: String, as type: T.Type) -> T? {
        guard let data = Data(base64URLEncoded: string) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }
}

extension Data {

    func base64URLEncodedString() -> String {
        var base64 = self.base64EncodedString()
        base64 = base64.replacingOccurrences(of: "+", with: "-")
        base64 = base64.replacingOccurrences(of: "/", with: "_")
        base64 = base64.replacingOccurrences(of: "=", with: "")
        return base64
    }

    init?(base64URLEncoded string: String) {
        var base64 = string
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")

        let remainder = base64.count % 4
        if remainder > 0 {
            base64 = base64.padding(toLength: base64.count + 4 - remainder,
                                   withPad: "=",
                                   startingAt: 0)
        }

        self.init(base64Encoded: base64)
    }
}

#if DEBUG
extension JWTService {

    static func generateTestToken() -> String {
        shared.generateAccessToken(
            userId: UUID(),
            username: "test_user",
            email: "test@example.com",
            expiresIn: 3600
        )
    }
}
#endif

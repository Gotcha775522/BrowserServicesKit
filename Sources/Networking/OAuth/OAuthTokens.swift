//
//  OAuthTokens.swift
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import JWTKit

public enum TokenPayloadError: Error {
    case InvalidTokenScope
}

public struct JWTAccessToken: JWTPayload {
    public let exp: ExpirationClaim
    public let iat: IssuedAtClaim
    public let sub: SubjectClaim
    public let aud: AudienceClaim
    public let iss: IssuerClaim
    public let jti: IDClaim
    public let scope: String
    public let api: String // always v2
    public let email: String?
    public let entitlements: [EntitlementPayload]

    public func verify(using signer: JWTKit.JWTSigner) throws {
        try self.exp.verifyNotExpired()
        if self.scope != "privacypro" {
            throw TokenPayloadError.InvalidTokenScope
        }
    }

    public func isExpired() -> Bool {
        do {
            try self.exp.verifyNotExpired()
        } catch {
            return true
        }
        return false
    }

    public var externalID: String {
        sub.value
    }
}

public struct JWTRefreshToken: JWTPayload {
    public let exp: ExpirationClaim
    public let iat: IssuedAtClaim
    public let sub: SubjectClaim
    public let aud: AudienceClaim
    public let iss: IssuerClaim
    public let jti: IDClaim
    public let scope: String
    public let api: String

    public func verify(using signer: JWTKit.JWTSigner) throws {
        try self.exp.verifyNotExpired()
        if self.scope != "refresh" {
            throw TokenPayloadError.InvalidTokenScope
        }
    }
}

public enum SubscriptionEntitlement: String, Codable {
    case networkProtection = "Network Protection"
    case dataBrokerProtection = "Data Broker Protection"
    case identityTheftRestoration = "Identity Theft Restoration"
    case unknown

    public init(from decoder: Decoder) throws {
        self = try Self(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

public struct EntitlementPayload: Codable {
    public let product: SubscriptionEntitlement // Can expand in future
    public let name: String // always `subscriber`
}

public struct TokensContainer: Codable, Equatable, CustomDebugStringConvertible {
    public  let accessToken: String
    public let refreshToken: String
    public let decodedAccessToken: JWTAccessToken
    public let decodedRefreshToken: JWTRefreshToken

    public static func == (lhs: TokensContainer, rhs: TokensContainer) -> Bool {
        lhs.accessToken == rhs.accessToken && lhs.refreshToken == rhs.refreshToken
    }

    public var debugDescription: String {
        """
        Access Token: \(decodedAccessToken)
        Refresh Token: \(decodedRefreshToken)
        """
    }
}

public extension JWTAccessToken {

    var subscriptionEntitlements: [SubscriptionEntitlement] {
        return entitlements.map({ entPayload in
            entPayload.product
        })
    }

    func hasEntitlement(_ entitlement: SubscriptionEntitlement) -> Bool {
        return subscriptionEntitlements.contains(entitlement)
    }
}
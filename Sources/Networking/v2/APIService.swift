//
//  APIService.swift
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
import os.log

public protocol APIService {
    typealias AuthorizationRefresherCallback = ((_: APIRequestV2) async throws -> String)
    var authorizationRefresherCallback: AuthorizationRefresherCallback? { get set }
    func fetch(request: APIRequestV2) async throws -> APIResponseV2
}

public class DefaultAPIService: APIService {
    private let urlSession: URLSession
    public var authorizationRefresherCallback: AuthorizationRefresherCallback?

    public init(urlSession: URLSession = .shared, authorizationRefresherCallback: AuthorizationRefresherCallback? = nil) {
        self.urlSession = urlSession
        self.authorizationRefresherCallback = authorizationRefresherCallback
    }

    /// Fetch an API Request
    /// - Parameter request: A configured APIRequest
    /// - Returns: An `APIResponseV2` containing the body data and the HTTPURLResponse
    public func fetch(request: APIRequestV2) async throws -> APIResponseV2 {

        Logger.networking.debug("Fetching: \(request.debugDescription)")
        let (data, response) = try await fetch(for: request.urlRequest)
        Logger.networking.debug("Response: \(response.debugDescription) Data size: \(data.count) bytes")

        try Task.checkCancellation()

        // Check response code
        let httpResponse = try response.asHTTPURLResponse()
        let responseHTTPStatus = httpResponse.httpStatus

        // First time the request is executed and the response is `.unauthorized` we try to refresh the authentication token
        if responseHTTPStatus == .unauthorized,
           request.isAuthenticated == true,
           request.authRefreshRetryCount == 0,
           let authorizationRefresherCallback {
            request.authRefreshRetryCount += 1

            // Ask to refresh the token
            let refreshedToken = try await authorizationRefresherCallback(request)
            request.updateAuthorizationHeader(refreshedToken)

            // Try again
            return try await fetch(request: request)
        }

        // It's a failure and the request must be retried
        if  let retryPolicy = request.retryPolicy,
            responseHTTPStatus.isFailure,
            responseHTTPStatus != .unauthorized, // No retries needed is unuathorised
            request.failureRetryCount < retryPolicy.maxRetries {
            request.failureRetryCount += 1

            if retryPolicy.delay > 0 {
                try? await Task.sleep(interval: retryPolicy.delay)
            }

            // Try again
            return try await fetch(request: request)
        }

        // It's not a failure, we check the constraints
        if !responseHTTPStatus.isFailure {
            try checkConstraints(in: httpResponse, for: request)
        }
        return APIResponseV2(data: data, httpResponse: httpResponse)
    }

    /// Check if the response satisfies the required constraints
    private func checkConstraints(in response: HTTPURLResponse, for request: APIRequestV2) throws {

        let httpResponse = try response.asHTTPURLResponse()
        let responseHTTPStatus = httpResponse.httpStatus
        let notModifiedIsAllowed: Bool = request.responseConstraints?.contains(.allowHTTPNotModified) ?? false
        if responseHTTPStatus == .notModified && !notModifiedIsAllowed {
            let error = APIRequestV2.Error.unsatisfiedRequirement(.allowHTTPNotModified)
            Logger.networking.error("Error: \(error.localizedDescription)")
            throw error
        }
        if let requirements = request.responseConstraints {
            for requirement in requirements {
                switch requirement {
                case .requireETagHeader:
                    guard httpResponse.etag != nil else {
                        let error = APIRequestV2.Error.unsatisfiedRequirement(requirement)
                        Logger.networking.error("Error: \(error.localizedDescription)")
                        throw error
                    }
                case .requireUserAgent:
                    guard let userAgent = httpResponse.allHeaderFields[HTTPHeaderKey.userAgent] as? String,
                          userAgent.isEmpty == false else {
                        let error = APIRequestV2.Error.unsatisfiedRequirement(requirement)
                        Logger.networking.error("Error: \(error.localizedDescription)")
                        throw error
                    }
                default:
                    break
                }
            }
        }

    }

    /// Fetch data using the class URL session, in case of error wraps it in a `APIRequestV2.Error.urlSession` error
    /// - Parameter request: The URLRequest to fetch
    /// - Returns: The Data fetched and the URLResponse
    private func fetch(for request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await urlSession.data(for: request)
        } catch let error {
            throw APIRequestV2.Error.urlSession(error)
        }
    }
}

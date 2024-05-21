//
//  PhishingDetectionClient.swift
//
//  Copyright © 2023 DuckDuckGo. All rights reserved.
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
import Common

public protocol PhishingDetectionClientProtocol {
    func updateFilterSet(revision: Int) async -> [Filter]
    func updateHashPrefixes(revision: Int) async -> [String]
    func getMatches(hashPrefix: String) async -> [Match]
}

class PhishingDetectionAPIClient: PhishingDetectionClientProtocol {
    
    enum Constants {
        static let productionEndpoint = URL(string: "https://tbd.unknown.duckduckgo.com")!
        static let stagingEndpoint = URL(string: "http://localhost:3000")!
    }
    
    private let endpointURL: URL
    private let session: URLSession = .shared
    private var headers: [String: String]? = [:]
    
    var filterSetURL: URL {
        endpointURL.appendingPathComponent("filterSet")
    }
    
    var hashPrefixURL: URL {
        endpointURL.appendingPathComponent("hashPrefix")
    }
    
    var matchesURL: URL {
        endpointURL.appendingPathComponent("matches")
    }
    
    init(environment: Environment = .staging) {
        switch environment {
        case .production:
            endpointURL = Constants.productionEndpoint
        case .staging:
            endpointURL = Constants.stagingEndpoint
        }
    }
    
    public func updateFilterSet(revision: Int) async -> [Filter] {
        let url: URL
        if revision > 0 {
            var urlComponents = URLComponents(url: filterSetURL, resolvingAgainstBaseURL: true)
            urlComponents?.queryItems = [URLQueryItem(name: "revision", value: String(revision))]
            guard let resolvedURL = urlComponents?.url else {
                os_log(.debug, log: .phishingDetection, "\(self): 🔸 Invalid filterSet revision URL: \(revision)")
                return []
            }
            url = resolvedURL
        } else {
            url = filterSetURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        do {
            let (data, _) = try await session.data(for: request)
            if let filterSetResponse = try? JSONDecoder().decode(FilterSetResponse.self, from: data) {
                return filterSetResponse.filters
            } else {
                os_log(.debug, log: .phishingDetection, "\(self): 🔸 Failed to decode filterSet response: \(data)")
            }
        } catch {
            os_log(.debug, log: .phishingDetection, "\(self): 🔴 Failed to load filterSet data: \(error)")
        }
        return []
    }
    
    public func updateHashPrefixes(revision: Int) async -> [String] {
        let url: URL
        if revision > 0 {
            var urlComponents = URLComponents(url: hashPrefixURL, resolvingAgainstBaseURL: true)
            urlComponents?.queryItems = [URLQueryItem(name: "revision", value: String(revision))]
            guard let resolvedURL = urlComponents?.url else {
                os_log(.debug, log: .phishingDetection, "\(self): 🔸 Invalid hashPrefix revision URL: \(revision)")
                return []
            }
            url = resolvedURL
        } else {
            url = hashPrefixURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        do {
            let (data, _) = try await session.data(for: request)
            if let hashPrefixResponse = try? JSONDecoder().decode(HashPrefixResponse.self, from: data) {
                return hashPrefixResponse.hashPrefixes
            } else {
                os_log(.debug, log: .phishingDetection, "\(self): 🔸 Failed to decode hashPrefix response: \(data)")
            }
        } catch {
            os_log(.debug, log: .phishingDetection, "\(self): 🔴 Failed to load hashPrefix data: \(error)")
        }
        return []
    }
    
    public func getMatches(hashPrefix: String) async -> [Match] {
        var urlComponents = URLComponents(url: matchesURL, resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = [URLQueryItem(name: "hashPrefix", value: hashPrefix)]
        
        guard let url = urlComponents?.url else {
            os_log(.debug, log: .phishingDetection, "\(self): 🔸 Invalid matches URL: \(hashPrefix)")
            return []
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        do {
            let (data, _) = try await session.data(for: request)
            if let matchResponse = try? JSONDecoder().decode(MatchResponse.self, from: data) {
                return matchResponse.matches
            } else {
                os_log(.debug, log: .phishingDetection, "\(self): 🔸 Failed to decode matches response: \(data)")
            }
        } catch {
            os_log(.debug, log: .phishingDetection, "\(self): 🔴 Failed to get matches: \(error)")
            return []
        }
        return []
    }
    
    enum Environment {
        case production
        case staging
    }
    
}

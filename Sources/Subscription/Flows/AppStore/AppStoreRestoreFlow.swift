//
//  AppStoreRestoreFlow.swift
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
import StoreKit
import os.log
import Networking

public enum AppStoreRestoreFlowError: LocalizedError, Equatable {
    case missingAccountOrTransactions
    case pastTransactionAuthenticationError
    case failedToObtainAccessToken
    case failedToFetchAccountDetails
    case failedToFetchSubscriptionDetails
    case subscriptionExpired

    public var errorDescription: String? {
        switch self {
        case .missingAccountOrTransactions:
            return "Missing account or transactions."
        case .pastTransactionAuthenticationError:
            return "Past transaction authentication error."
        case .failedToObtainAccessToken:
            return "Failed to obtain access token."
        case .failedToFetchAccountDetails:
            return "Failed to fetch account details."
        case .failedToFetchSubscriptionDetails:
            return "Failed to fetch subscription details."
        case .subscriptionExpired:
            return "Subscription expired."
        }
    }
}

@available(macOS 12.0, iOS 15.0, *)
public protocol AppStoreRestoreFlow {
    @discardableResult func restoreAccountFromPastPurchase() async -> Result<Void, AppStoreRestoreFlowError>
}

@available(macOS 12.0, iOS 15.0, *)
public final class DefaultAppStoreRestoreFlow: AppStoreRestoreFlow {
    private let subscriptionManager: SubscriptionManager
    private let storePurchaseManager: StorePurchaseManager
    private let subscriptionEndpointService: SubscriptionEndpointService

    public init(subscriptionManager: SubscriptionManager,
                storePurchaseManager: any StorePurchaseManager,
                subscriptionEndpointService: any SubscriptionEndpointService) {
        self.subscriptionManager = subscriptionManager
        self.storePurchaseManager = storePurchaseManager
        self.subscriptionEndpointService = subscriptionEndpointService
    }

    @discardableResult
    public func restoreAccountFromPastPurchase() async -> Result<Void, AppStoreRestoreFlowError> {
        Logger.subscriptionAppStoreRestoreFlow.log("Restoring account from past purchase")

        // Clear subscription Cache
        subscriptionEndpointService.clearSubscription()
        guard let lastTransactionJWSRepresentation = await storePurchaseManager.mostRecentTransaction() else {
            Logger.subscriptionAppStoreRestoreFlow.error("Missing last transaction")
            return .failure(.missingAccountOrTransactions)
        }

        do {
            let subscription = try await subscriptionManager.getSubscriptionFrom(lastTransactionJWSRepresentation: lastTransactionJWSRepresentation)
            if subscription.isActive {
                return .success(())
            } else {
                Logger.subscriptionAppStoreRestoreFlow.error("Subscription expired")

                // Removing all traces of the subscription and the account
                subscriptionManager.signOut()

                return .failure(.subscriptionExpired)
            }
        } catch {
            Logger.subscriptionAppStoreRestoreFlow.error("Error activating past transaction: \(error, privacy: .public)")
            return .failure(.pastTransactionAuthenticationError)
        }
    }
}

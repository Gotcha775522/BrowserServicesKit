//
//  Logger+Subscription.swift
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
import os.log

public extension Logger {
    static var subscription = { Logger(subsystem: "Subscription", category: "") }()
    static var subscriptionAppStorePurchaseFlow = { Logger(subsystem: "Subscription", category: "AppStorePurchaseFlow") }()
    static var subscriptionAppStoreRestoreFlow = { Logger(subsystem: "Subscription", category: "AppStoreRestoreFlow") }()
    static var subscriptionStripePurchaseFlow = { Logger(subsystem: "Subscription", category: "StripePurchaseFlow") }()
    static var subscriptionEndpointService = { Logger(subsystem: "Subscription", category: "EndpointService") }()
    static var subscriptionStorePurchaseManager = { Logger(subsystem: "Subscription", category: "StorePurchaseManager") }()
    static var subscriptionKeychain = { Logger(subsystem: "Subscription", category: "KeyChain") }()
    static var subscriptionCookieManager = { Logger(subsystem: "Subscription", category: "CookieManager") }()
}

//
//  URL+Subscription.swift
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

public extension URL {

    static var subscriptionBaseURL: URL {
        URL(string: "https://duckduckgo.com/subscriptions")!
    }

    static var identityTheftRestorationBaseURL: URL {
        URL(string: "https://duckduckgo.com/identity-theft-restoration")!
    }

    static var subscriptionFAQ: URL {
        URL(string: "https://duckduckgo.com/duckduckgo-help-pages/privacy-pro/")!
    }

    static var manageSubscriptionsInAppStoreAppURL: URL {
        URL(string: "macappstores://apps.apple.com/account/subscriptions")!
    }
}

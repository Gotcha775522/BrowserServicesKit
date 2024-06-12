//
//  File.swift
//  
//
//  Created by Thom on 04/05/2024.
//

import Foundation
import XCTest
@testable import PhishingDetection

class PhishingDetectionDataActivitiesTests: XCTestCase {
    var mockDetectionService: MockPhishingDetectionService!
    var activities: PhishingDetectionDataActivities!

    override func setUp() {
        super.setUp()
        mockDetectionService = MockPhishingDetectionService()
        activities = PhishingDetectionDataActivities(detectionService: mockDetectionService, hashPrefixInterval: 1, filterSetInterval: 1)
    }

    func testRun() async {
        let expectation = XCTestExpectation(description: "updateHashPrefixes and updateFilterSet completes")

        mockDetectionService.completionHandler = {
            expectation.fulfill()
        }

        await activities.run()
        
        await fulfillment(of: [expectation], timeout: 10.0)

        XCTAssertTrue(mockDetectionService.didUpdateHashPrefixes)
        XCTAssertTrue(mockDetectionService.didUpdateFilterSet)

    }
}

class HashPrefixDataActivityTests: XCTestCase {
    var mockDetectionService: MockPhishingDetectionService!
    var mockScheduler: MockBackgroundActivityScheduler!
    var activity: HashPrefixDataActivity!

    override func setUp() {
        super.setUp()
        mockDetectionService = MockPhishingDetectionService()
        mockScheduler = MockBackgroundActivityScheduler()
        activity = HashPrefixDataActivity(identifier: "test", detectionService: mockDetectionService, interval: 1, scheduler: mockScheduler)
    }

    func testStart() {
        activity.start()
        XCTAssertTrue(mockScheduler.startCalled)
    }

    func testStop() {
        activity.stop()
        XCTAssertTrue(mockScheduler.stopCalled)
    }
}

class FilterSetDataActivityTests: XCTestCase {
    var mockDetectionService: MockPhishingDetectionService!
    var mockScheduler: MockBackgroundActivityScheduler!
    var activity: FilterSetDataActivity!

    override func setUp() {
        super.setUp()
        mockDetectionService = MockPhishingDetectionService()
        mockScheduler = MockBackgroundActivityScheduler()
        activity = FilterSetDataActivity(identifier: "test", detectionService: mockDetectionService, interval: 1, scheduler: mockScheduler)
    }

    func testStart() {
        activity.start()
        XCTAssertTrue(mockScheduler.startCalled)
    }

    func testStop() {
        activity.stop()
        XCTAssertTrue(mockScheduler.stopCalled)
    }
}
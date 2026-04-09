//
//  Test.swift
//  LLCore
//
//  Created by Aleh Fiodarau on 08/04/2026.
//

import Testing
@testable import LLCore

@MainActor
struct PollingStrategyTest {
    
    // to capture a ref and change it inside a closure
    class BoolRef {
        var value: Bool
        init(_ value: Bool) { self.value = value }
    }
    
    lazy var pollingStrategy: PollingStrategy<Double> = PollingStrategy(
        frequencyProvider: frequency,
        shouldContinue: shouldContinue,
        fetchHandler: fetchHandler,
        updateHandler: updateHandler,
        errorHandler: { _ in })
    

    var frequency: () -> Double = { return 1.0 }
    var shouldContinue: () -> Bool = { true }
    var fetchHandler: () async throws -> Double = { return 1.0 }
    var updateHandler: (Double) -> Void = { _ in }
    //public typealias ErrorHandler = (Error) -> Void

    @Test("Tests if there is any delay before the first API call. It should be none.")
    mutating func testInitialDelay() async throws {
        
        let shouldProceed: BoolRef = BoolRef(true)
        
        self.frequency = { return 1 }
        self.shouldContinue = { shouldProceed.value }
        
        let clock = ContinuousClock()
        let startTime = clock.now
        
        await withCheckedContinuation { continuation in
            self.fetchHandler = {
                let elapsed = clock.now - startTime
                #expect(elapsed < .seconds(0.5))
                continuation.resume()
                // stop the  polling loop
                shouldProceed.value = false
                return 1.0
            }
            self.pollingStrategy.start()
        }

    }

}

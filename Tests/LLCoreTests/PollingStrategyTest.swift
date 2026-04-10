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
        errorHandler: errorHandler )
    

    var frequency: () -> Double = { return 1.0 }
    var shouldContinue: () -> Bool = { true }
    var fetchHandler: () async throws -> Double = { return 1.0 }
    var updateHandler: (Double) -> Void = { _ in }
    var errorHandler: (Error) -> Void = { _ in }

    @Test("Tests if there is any delay before the first API call. It should be none.")
    mutating func testInitialDelay() async throws {
        
        let shouldProceed: BoolRef = BoolRef(true)
        
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
    
    @Test("Test inflight cancellation")
    mutating func testInFlightCancellation() async throws {
        
        self.frequency = { return 3 }
        let clock = ContinuousClock()
        
        errorHandler = { error in
            // we should not receive a CancellationError
            #expect(!(error is CancellationError))
        }
        
        await withCheckedContinuation { continuation in
            
            self.fetchHandler = {
                // Simulate a long-running network request
                do {
                    try await clock.sleep(for: .seconds(2))
                    Issue.record("This part of the code should not be reached")
                    continuation.resume()
                }
                catch {
                    continuation.resume()
                    throw error
                    
                }
                
                return 1.0
            }
            
            let strategy = self.pollingStrategy // Capture the strategy
            strategy.start()
            
            // Use Task to handle async work
            Task {
                // Give the network request time to start
                try? await Task.sleep(for: .milliseconds(100))
                strategy.stop() // Use captured strategy
            }

        }
    }

}

//
//  PollingStrategy.swift
//  LLCore
//
//  Created by Aleh Fiodarau on 29/11/2025.
//

import Foundation

@MainActor
final public class PollingStrategy<Output> {
    public typealias FrequencyProvider = () -> Double
    public typealias FetchHandler = () async throws -> Output
    public typealias UpdateHandler = (Output) -> Void
    public typealias ErrorHandler = (Error) -> Void
    
    private let getFrequency: FrequencyProvider
    private let fetchHandler: FetchHandler
    private let updateHandler: UpdateHandler
    private let errorHandler: ErrorHandler

    // reconnection controls
    private var reconnectionAttempts = 0
    private var maxReconnectionAttempts = 5
    private var reconnectionDelay: Double = 1.0
    
    // query closure to check if connection is in proper state (i.e. .connected)
    private let shouldContinue: () -> Bool
    
    private var pollingTask: Task<Void, Never>?
    
    public init(frequencyProvider: @escaping FrequencyProvider,
         shouldContinue: @escaping () -> Bool,
         fetchHandler: @escaping FetchHandler,
         updateHandler: @escaping UpdateHandler,
         errorHandler: @escaping ErrorHandler)
    {
        self.getFrequency = frequencyProvider
        self.shouldContinue = shouldContinue
        self.fetchHandler = fetchHandler
        self.updateHandler = updateHandler
        self.errorHandler = errorHandler
    }
    
    @available(macOS 13.0, iOS 16.0, *)
    public func start<C: Clock>(clock: C = ContinuousClock()) where C.Duration == Duration {
        stop()
        
        pollingTask = Task {
            while !Task.isCancelled && shouldContinue() {
                
                do {
                    let data = try await fetchHandler()
                    updateHandler(data)

                    // reset reconnection state
                    reconnectionAttempts = 0
                    reconnectionDelay = 1.0
                    
                    // wait before making another API call
                    try? await clock.sleep(for: .seconds(getFrequency()))

                } catch {
                    guard !(error is CancellationError) else { return }
                    
                    errorHandler(error)
                    
                    guard reconnectionAttempts < maxReconnectionAttempts else {
                        // Max attempts reached, stop polling
                        break
                    }
                    reconnectionAttempts += 1
                    reconnectionDelay *= 2
                    
                    // Wait with exponential backoff before next attempt
                    try? await clock.sleep(for: .seconds(reconnectionDelay))
                }
            }
        }
    }
    
    public func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}

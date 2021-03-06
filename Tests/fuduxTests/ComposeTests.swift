//
//  composeTests.swift
//  fuduxTests
//
//  Created by Daniel Garcia
//

@testable import fudux
import XCTest

final class ComposeTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()

        loggedActions = [:]
        orderedValues = []
    }

    func test_function_composition_is_valid_for_arbitrary_types() {
        func firstFunc(_ value: Int) -> Int { Int(arc4random_uniform(UInt32(value))) }
        func secondFunc(_ number: Int) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .spellOut
            return formatter.string(from: number as NSNumber) ?? ""
        }

        let sut = firstFunc >>> secondFunc
        let result = sut(10)
        XCTAssert(result.isEmpty == false, "Expected a non-empty string!")
    }

    func test_enhancing_store_with_plain_enhancers() throws {
        let firstValue = "first"
        let secondValue = "second"
        let firstEnhancer: StoreEnhancer<ReduxAppState> = firstEnhancingFunction(firstValue)
        let secondEnhancer: StoreEnhancer<ReduxAppState> = secondEnhancingFunction(secondValue)
        let expectedState = ReduxAppState(title: "New title", isLoading: false, sideEffectResult: .idle)

        let sut = firstEnhancer >>> secondEnhancer
        let enhancedStore = sut(createStore)
        let (dispatch, _, getState) = enhancedStore(reduxReducer, ReduxAppState.initialState)

        dispatch(ReduxAction.setTitle("New title"))

        XCTAssert(
            expectedState == getState(),
            "Expected state to be \(expectedState) but found \(getState())"
        )
        
        let firstLoggedAction = try XCTUnwrap(loggedActions[firstValue])
        XCTAssertNotNil(
            loggedActions[firstValue],
            "Expected to have logged <ReduxAction.setTitle> but found \(firstLoggedAction))"
        )
        
        let secondLoggedAction = try XCTUnwrap(loggedActions[secondValue])
        XCTAssertNotNil(
            loggedActions[secondValue],
            "Expected to have logged <ReduxAction.setTitle> but found \(secondLoggedAction))"
        )
        XCTAssert(
            try XCTUnwrap(orderedValues.first == firstValue),
            "Expected to find value \(firstValue) but got \(orderedValues[0])"
        )
        XCTAssert(
            try XCTUnwrap(orderedValues[1] == secondValue),
            "Expected to find value \(secondValue) but got \(orderedValues[1])"
        )
    }

    func test_enhancing_store_with_middleware_first() throws {
        let firstValue = "one"
        let secondValue = "two"
        let firstEnhancer: StoreEnhancer<ReduxAppState> = firstEnhancingFunction(firstValue)
        let secondEnhancer: StoreEnhancer<ReduxAppState> = secondEnhancingFunction(secondValue)
        let middleware = applyMiddleware(middlewares: [dummyMiddleware()])
        let expectedState = ReduxAppState(title: "New title", isLoading: false, sideEffectResult: .idle)
        let expectedNumberOfItemsAfterMiddleware = 2

        // Set the middleware first in the chain
        // Its job is to erase <loggedActions> & <orderedValues> BEFORE the enhancers are run
        let sut = middleware >>> firstEnhancer >>> secondEnhancer
        let enhancedStore = sut(createStore)
        let (dispatch, _, getState) = enhancedStore(reduxReducer, ReduxAppState.initialState)
        
        // MARK: - Precondition: Prepopulate array & dictionary
        loggedActions = ["to_be_removed_by_middleware": ReduxAction.isLoading(true)]
        orderedValues = ["to_be_removed_by_middleware"]

        dispatch(ReduxAction.setTitle("New title"))

        XCTAssert(
            expectedState == getState(),
            "Expected state to be \(expectedState) but found \(getState()) instead"
        )
        XCTAssert(
            loggedActions.count == expectedNumberOfItemsAfterMiddleware,
            "Expected to find \(expectedNumberOfItemsAfterMiddleware) items but got \(loggedActions.count) instead"
        )
        
        let firstLoggedAction = try XCTUnwrap(loggedActions[firstValue])
        XCTAssertNotNil(
            loggedActions[firstValue],
            "Expected to have logged <ReduxAction.setTitle> but found \(firstLoggedAction))"
        )
        
        let secondLoggedAction = try XCTUnwrap(loggedActions[secondValue])
        XCTAssertNotNil(
            loggedActions[secondValue],
            "Expected to have logged <ReduxAction.setTitle> but found \(secondLoggedAction))"
        )
        XCTAssert(
            try XCTUnwrap(orderedValues.first == firstValue),
            "Expected to find value \(firstValue) but got \(orderedValues[0])"
        )
        XCTAssert(
            try XCTUnwrap(orderedValues[1] == secondValue),
            "Expected to find value \(secondValue) but got \(orderedValues[1])"
        )
    }

    func test_enhancing_store_with_middleware_last() {
        let firstValue = "one"
        let secondValue = "two"
        let firstEnhancer: StoreEnhancer<ReduxAppState> = firstEnhancingFunction(firstValue)
        let secondEnhancer: StoreEnhancer<ReduxAppState> = secondEnhancingFunction(secondValue)
        let middleware = applyMiddleware(middlewares: [dummyMiddleware()])
        let expectedState = ReduxAppState(title: "New title", isLoading: false, sideEffectResult: .idle)

        // Set the middleware last in the chain
        // Its job is to erase <loggedActions> & <orderedValues> AFTER the enhancers are run
        let sut = firstEnhancer >>> secondEnhancer >>> middleware
        let enhancedStore = sut(createStore)
        let (dispatch, _, getState) = enhancedStore(reduxReducer, ReduxAppState.initialState)
        
        // MARK: - Precondition: Prepopulate array & dictionary
        loggedActions = ["to_be_removed_by_middleware": ReduxAction.isLoading(true)]
        orderedValues = ["to_be_removed_by_middleware"]

        dispatch(ReduxAction.setTitle("New title"))

        XCTAssert(
            expectedState == getState(),
            "Expected state to be \(expectedState) but found \(getState()) instead"
        )
        XCTAssert(
            loggedActions.count == 0,
            "Expected <loggedActions> to have been emptied by middleware! Got \(loggedActions.count)"
        )
        XCTAssert(
            orderedValues.count == 0,
            "Expected <orderedValues> to have been emptied by middleware! Got \(orderedValues.count)"
        )
    }
}

// MARK: - Test helpers

private var loggedActions = [String: Action]()
private var orderedValues: [String] = []

// None of these enhancers swallow actions from original store's dispatch!!
private func firstEnhancingFunction<State>(_ value: String) -> StoreEnhancer<State> {
    { createStore in {
        reducer, state in
        let (storeDispatch, storeSubscribe, storeGetState) = createStore(reducer, state)

        let loggingThunk: DispatchFunction = { action in
            storeDispatch(action)
            loggedActions[value] = action
            orderedValues.append(value)
        }

        return (loggingThunk, storeSubscribe, storeGetState)
    }
    }
}

private func secondEnhancingFunction<State>(_ value: String) -> StoreEnhancer<State> {
    { createStore in {
        reducer, state in
        let (storeDispatch, storeSubscribe, storeGetState) = createStore(reducer, state)

        let loggingThunk: DispatchFunction = { action in
            storeDispatch(action)
            loggedActions[value] = action
            orderedValues.append(value)
        }

        return (loggingThunk, storeSubscribe, storeGetState)
    }
    }
}

// MARK: - Plain simple middleware

private func dummyMiddleware() -> Middleware<ReduxAppState> {
    { _, _ in { next in
        { action in
            next(action)

            switch action as! ReduxAction {
            case .setTitle:
                loggedActions = [:]
                orderedValues = []
            default:
                break
            }
        }
    }
    }
}

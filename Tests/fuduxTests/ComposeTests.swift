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
    
    func test_enhancing_store() throws {
        let firstEnhancer: StoreEnhancer<ReduxAppState> = firstEnhancingFunction("first")
        let secondEnhancer: StoreEnhancer<ReduxAppState> = secondEnhancingFunction("second")
        let expectedState = ReduxAppState(title: "New title", isLoading: false, sideEffectResult: .idle)
        
        let sut = firstEnhancer >>> secondEnhancer
        let enhancedStore = sut(createStore)
        let (dispatch, _, getState) = enhancedStore(reduxReducer, ReduxAppState.initialState)
        
        dispatch(ReduxAction.setTitle("New title"))
        
        XCTAssert(
            expectedState == getState(),
            "Expected states to match but found \(getState())"
        )
        XCTAssertNotNil(
            loggedActions["first"],
            "Expected to have logged <ReduxAction.setTitle> but found \(loggedActions["first"]!))"
        )
        XCTAssertNotNil(
            loggedActions["second"],
            "Expected to have logged <ReduxAction.setTitle> but found \(loggedActions["first"]!))"
        )
        XCTAssert(
            try XCTUnwrap(orderedValues.first == "first"),
            "Expected to find value <first> but got \(orderedValues.first!)"
        )
        XCTAssert(
            try XCTUnwrap(orderedValues[1] == "second"),
            "Expected to find value <second> but got \(orderedValues[1])"
        )
    }
    
    func test_enhancing_store_with_middlewares_first() {
        let firstEnhancer: StoreEnhancer<ReduxAppState> = firstEnhancingFunction("one")
        let secondEnhancer: StoreEnhancer<ReduxAppState> = secondEnhancingFunction("two")
        let middleware = applyMiddleware(middlewares: [dummyMiddleware()])
        let expectedState = ReduxAppState(title: "New title", isLoading: false, sideEffectResult: .idle)
        
        // Set the middleware first on the chain
        // Its job is to "clean" "loggedActions" & "orderedValues" BEFORE the enhancers are run
        let sut = middleware >>> firstEnhancer >>> secondEnhancer
        let enhancedStore = sut(createStore)
        let (dispatch, _, getState) = enhancedStore(reduxReducer, ReduxAppState.initialState)
        loggedActions = ["fake":ReduxAction.isLoading(true)]
        orderedValues = ["fake"]

        dispatch(ReduxAction.setTitle("New title"))
        
        XCTAssert(
            expectedState == getState(),
            "Expected states to be \(expectedState) but found \(getState())"
        )
        XCTAssert(
            loggedActions.count == 2,
            "Expected middleware to have had removed 1 item but got \(loggedActions.count) instead"
        )
        XCTAssertNotNil(
            loggedActions["one"],
            "Expected to have logged <ReduxAction.setTitle> but found \(loggedActions["one"]!))"
        )
        XCTAssertNotNil(
            loggedActions["two"],
            "Expected to have logged <ReduxAction.setTitle> but found \(loggedActions["two"]!))"
        )
        XCTAssert(
            try XCTUnwrap(orderedValues.first == "one"),
            "Expected to find value <one> but got \(orderedValues.first!)"
        )
        XCTAssert(
            try XCTUnwrap(orderedValues[1] == "two"),
            "Expected to find value <two> but got \(orderedValues[1])"
        )
    }
    
    func test_enhancing_store_with_middlewares_last() {
        let firstEnhancer: StoreEnhancer<ReduxAppState> = firstEnhancingFunction("one")
        let secondEnhancer: StoreEnhancer<ReduxAppState> = secondEnhancingFunction("two")
        let middleware = applyMiddleware(middlewares: [dummyMiddleware()])
        let expectedState = ReduxAppState(title: "New title", isLoading: false, sideEffectResult: .idle)
        
        // Set the middleware last on the chain
        // Its job is to "clean" "loggedActions" & "orderedValues" AFTER the enhancers are run
        let sut = firstEnhancer >>> secondEnhancer >>> middleware
        let enhancedStore = sut(createStore)
        let (dispatch, _, getState) = enhancedStore(reduxReducer, ReduxAppState.initialState)
        loggedActions = ["fake":ReduxAction.isLoading(true)]
        orderedValues = ["fake"]

        dispatch(ReduxAction.setTitle("New title"))
        
        XCTAssert(
            expectedState == getState(),
            "Expected states to be \(expectedState) but found \(getState())"
        )
        XCTAssert(
            loggedActions.count == 0,
            "Expected <loggedActions> to have been cleaned by middleware! Got \(loggedActions.count)"
        )
        XCTAssert(
            orderedValues.count == 0,
            "Expected <orderedValues> to have been cleaned by middleware! Got \(orderedValues.count)"
        )
    }
}

private var loggedActions = [String: Action]()
private var orderedValues: [String] = []

// None of these enhancers swallow actions from original store's dispatch!!
private func firstEnhancingFunction<State>(_ value: String) -> StoreEnhancer<State> {
    return { createStore in {
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
    return { createStore in {
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
//
//  ReduxIntegrationTests.swift
//  fuduxTests
//
//  Created by Daniel Garcia
//

@testable import fudux
import XCTest

let delay: TimeInterval = 0.1

final class ReduxIntegrationTests: XCTestCase {
    func test_title_is_updated_by_reducer_and_subscriber_gets_updated() {
        var expectedState: ReduxAppState!
        let observer = Observer<ReduxAppState> { expectedState = $0 }
        let middleware = applyMiddleware(middlewares: [reduxMiddleware()])
        let (sutDispatch, sutSubscribe, sutGetState) = middleware(createStore)(reduxReducer, ReduxAppState.initialState)
        _ = sutSubscribe(observer)

        sutDispatch(ReduxAction.setTitle("New title"))

        XCTAssert(
            expectedState.title == sutGetState().title,
            "Expected titles to match but got \(expectedState.title) instead"
        )
        XCTAssert(
            expectedState.isLoading == false,
            "Expected to NOT be loading but found \(expectedState.isLoading)"
        )
        XCTAssert(
            expectedState.sideEffectResult == .idle,
            "Expected result to be <.idle> but got \(expectedState.sideEffectResult)"
        )
    }

    func test_loading_state_is_updated_by_reducer_and_subscriber_gets_updated() {
        var expectedState: ReduxAppState!
        let observer = Observer<ReduxAppState> { expectedState = $0 }
        let middleware = applyMiddleware(middlewares: [reduxMiddleware()])
        let (sutDispatch, sutSubscribe, sutGetState) = middleware(createStore)(reduxReducer, ReduxAppState.initialState)
        _ = sutSubscribe(observer)

        sutDispatch(ReduxAction.isLoading(true))

        XCTAssert(
            expectedState.title == sutGetState().title,
            "Expected titles to match but got \(expectedState.title) instead"
        )
        XCTAssert(
            expectedState.isLoading == sutGetState().isLoading,
            "Expected loading states to match but found \(expectedState.isLoading)"
        )
        XCTAssert(
            expectedState.sideEffectResult == .idle,
            "Expected result to be <.idle> but got \(expectedState.sideEffectResult)"
        )
    }

    func test_middleware_triggers_action_after_async_operation() {
        var expectedState: ReduxAppState!
        let observer = Observer<ReduxAppState> { expectedState = $0 }
        let asyncExpectation = expectation(description: "Async operation on middleware")
        let middleware = applyMiddleware(middlewares: [reduxMiddleware(testExpectation: asyncExpectation)])
        let (sutDispatch, sutSubscribe, sutGetState) = middleware(createStore)(reduxReducer, ReduxAppState.initialState)
        _ = sutSubscribe(observer)

        sutDispatch(ReduxAction.triggerAsyncOperation)

        XCTAssert(
            expectedState.title == sutGetState().title,
            "Expected titles to match but got \(expectedState.title) instead"
        )
        XCTAssert(
            expectedState.isLoading == sutGetState().isLoading,
            "Expected loading states to match but found \(expectedState.isLoading)"
        )

        waitForExpectations(timeout: delay + 0.1, handler: nil)
        XCTAssert(
            expectedState.sideEffectResult == .success("middleware-success"),
            "Expected result to be <.success(middleware-success)> but got \(expectedState.sideEffectResult)"
        )
    }
}

// MARK: - AppState

struct ReduxAppState: Equatable {
    let title: String
    let isLoading: Bool
    let sideEffectResult: SideEffectResult
}

extension ReduxAppState {
    enum SideEffectResult: Equatable {
        case idle
        case success(String)
        case failure(String)
    }
}

extension ReduxAppState {
    static var initialState = ReduxAppState(title: "initialState", isLoading: false, sideEffectResult: .idle)
}

// MARK: - Actions

enum ReduxAction: Action {
    case setTitle(String)
    case isLoading(Bool)
    case triggerAsyncOperation
    case setSideEffectResult(ReduxAppState.SideEffectResult)
}

// MARK: - Reducer

func reduxReducer(action: Action, state: inout ReduxAppState) {
    guard let action = action as? ReduxAction else { return }

    switch action {
    case let .setTitle(value):
        state = ReduxAppState(
            title: value,
            isLoading: state.isLoading,
            sideEffectResult: state.sideEffectResult
        )
    case let .isLoading(value):
        state = ReduxAppState(
            title: state.title,
            isLoading: value,
            sideEffectResult: state.sideEffectResult
        )
    case let .setSideEffectResult(value):
        state = ReduxAppState(
            title: state.title,
            isLoading: state.isLoading,
            sideEffectResult: value
        )
    case .triggerAsyncOperation:
        state = ReduxAppState(
            title: state.title,
            isLoading: state.isLoading,
            sideEffectResult: state.sideEffectResult
        )
    }
}

// MARK: - Middleware

func reduxMiddleware(testExpectation: XCTestExpectation? = nil) -> Middleware<ReduxAppState> {
    { _, dispatchFunction in {
        next in {
            action in
            next(action)

            guard let action = action as? ReduxAction else { return }

            switch action {
            case .triggerAsyncOperation:
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    dispatchFunction(
                        ReduxAction
                            .setSideEffectResult(ReduxAppState.SideEffectResult.success("middleware-success"))
                    )
                    testExpectation?.fulfill()
                }
            default: break
            }
        }
    }
    }
}

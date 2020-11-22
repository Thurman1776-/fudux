@testable import fudux
import XCTest

final class ApplyMiddleware: XCTestCase {
    override func tearDown() {
        super.tearDown()
        actionsRecorder = []
    }

    func test_middlewares_are_run_in_correct_order() {
        let expectedState = CounterState(count: 2)
        let counterState = CounterState(count: 0)
        let middlewares = applyMiddleware(middlewares: [
            firstMiddleware(),
            secondMiddleware(),
        ])
        let (dispatch, _, getState) = middlewares(createStore)(middlewareReducer, counterState)

        dispatch(MiddlewareActions.first)

        XCTAssert(
            getState() == expectedState,
            "Expected states to be <\(expectedState)> but found - <\(getState())>"
        )
        XCTAssert(
            actionsRecorder[0] as? MiddlewareActions == MiddlewareActions.first,
            "Expected to find <MiddlewareActions.first>! Found <\(actionsRecorder[0]) instead>"
        )
        XCTAssert(
            actionsRecorder[1] as? MiddlewareActions == MiddlewareActions.second,
            "Expected to find <MiddlewareActions.second>! Found <\(actionsRecorder[1]) instead>"
        )
    }

    func test_middlewares_can_supress_actions() {
        let expectedState = CounterState(count: 0)
        let counterState = CounterState.initialState
        let middlewares = applyMiddleware(middlewares: [
            supressingMiddleware(),
            // This middleware must not be called
            firstMiddleware(),
        ])
        let (dispatch, _, getState) = middlewares(createStore)(middlewareReducer, counterState)

        dispatch(MiddlewareActions.fourth)

        XCTAssert(
            getState() == expectedState,
            "Expected <\(expectedState)> to have not changed but found - <\(getState())>"
        )
        XCTAssert(
            actionsRecorder[0] as? MiddlewareActions == MiddlewareActions.fourth,
            "Expected to find <MiddlewareActions.first>! Found <\(actionsRecorder[0]) instead>"
        )
    }

    func test_middlewares_can_replace_action() {
        let expectedState = CounterState(count: 2)
        let counterState = CounterState.initialState
        let middlewares = applyMiddleware(middlewares: [
            firstMiddleware(),
        ])
        let (dispatch, _, getState) = middlewares(createStore)(middlewareReducer, counterState)

        dispatch(MiddlewareActions.first)

        XCTAssert(
            getState() == expectedState,
            "Expected <\(expectedState)> to equal - <\(getState())> as action was replaced  with <MiddlewareActions.second>"
        )
    }

    func test_middlewares_can_dispatch_actions() {
        let expectedState = CounterState(count: 1)
        let counterState = CounterState.initialState
        let middlewares = applyMiddleware(middlewares: [
            dispatchingMiddleware(),
        ])
        let (dispatch, _, getState) = middlewares(createStore)(middlewareReducer, counterState)

        dispatch(MiddlewareActions.third)

        XCTAssert(
            getState() == expectedState,
            "Expected <\(expectedState)> to equal - <\(getState())>"
        )
        XCTAssert(
            actionsRecorder[0] as? MiddlewareActions == MiddlewareActions.third,
            "Expected to find <MiddlewareActions.third>! Found <\(actionsRecorder[0]) instead>"
        )
        XCTAssert(
            actionsRecorder[1] as? MiddlewareActions == MiddlewareActions.first,
            "Expected to find <MiddlewareActions.first>! Found <\(actionsRecorder[1]) instead>"
        )
    }

    func test_middlewares_can_retrieve_current_state() {
        let expectedState = CounterState(count: 4)
        let counterState = CounterState.initialState
        let middlewares = applyMiddleware(middlewares: [
            storeReadOnlyMiddleware(),
        ])
        let (dispatch, _, getState) = middlewares(createStore)(middlewareReducer, counterState)

        dispatch(MiddlewareActions.first)

        XCTAssert(
            getState() == expectedState,
            "Expected <\(expectedState)> to equal - <\(getState())>"
        )
        XCTAssert(
            actionsRecorder.count == 2,
            "Expected to find 2 actions but got - \(actionsRecorder.count)"
        )
    }
}

// MARK: - Tests utils

private enum MiddlewareActions: Action {
    case first
    case second
    case third
    case fourth
}

private func middlewareReducer(action: Action, state: inout CounterState) {
    switch action as! MiddlewareActions {
    case .first:
        state = CounterState(count: 1)
    case .second:
        state = CounterState(count: 2)
    case .third:
        state = CounterState(count: 3)
    case .fourth:
        state = CounterState(count: 4)
    }
}

private var actionsRecorder: [Action] = []
private func saveAction(action: Action) {
    actionsRecorder.append(action)
}

// This middleware is replacing the original action (.first) with .second.
// Intended for testing purposes
private func firstMiddleware() -> Middleware<CounterState> {
    { _, _ in { next in
        { action in
            switch action {
            case MiddlewareActions.first:
                saveAction(action: action)
                next(MiddlewareActions.second)
            default:
                break
            }
        }
    }
    }
}

private func secondMiddleware() -> Middleware<CounterState> {
    { _, _ in { next in
        { action in
            switch action {
            case MiddlewareActions.second:
                saveAction(action: action)
                next(action)
            default:
                break
            }
        }
    }
    }
}

// This middleware is effectively supressing the incoming action
// preveting it to reach the store's reducer
private func supressingMiddleware() -> Middleware<CounterState> {
    { _, _ in { _ in
        { action in
            switch action {
            case MiddlewareActions.fourth:
                saveAction(action: action)
            default:
                break
            }
        }
    }
    }
}

private func dispatchingMiddleware() -> Middleware<CounterState> {
    { _, dispatchFunction in { next in
        { action in
            switch action {
            case MiddlewareActions.third:
                saveAction(action: action)
                dispatchFunction(MiddlewareActions.first)
            case MiddlewareActions.first:
                saveAction(action: action)
                next(action)
            default:
                break
            }
        }
    }
    }
}

private func storeReadOnlyMiddleware() -> Middleware<CounterState> {
    { getState, dispatchFunction in { next in
        { action in
            switch action {
            case MiddlewareActions.first:
                next(action)
                saveAction(action: action)
                dispatchFunction(MiddlewareActions.fourth)
            case MiddlewareActions.fourth:
                if getState().count == 1 {
                    saveAction(action: action)
                    next(action)
                }
            default:
                next(action)
            }
        }
    }
    }
}

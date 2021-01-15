//
//  CreateStoreTests.swift
//  fuduxTests
//
//  Created by Daniel Garcia
//

@testable import fudux
import XCTest

final class CreateStoreTests: XCTestCase {
    func test_create_store_sets_correct_initial_state() {
        let initialState = CounterState(count: 0)
        let sut: StoreAPI<CounterState> = createStore

        let (_, _, getState) = sut(testReducer, initialState)

        XCTAssertEqual(
            getState(), initialState,
            "Expected states to be equal but found \(getState())"
        )
    }

    func test_create_store_updates_state_using_reducer() {
        let initialState = CounterState(count: 0)
        let expectedState = CounterState(count: 1)
        let sut: StoreAPI<CounterState> = createStore

        let (dispatch, _, getState) = sut(testReducer, initialState)
        dispatch(TestAction.input)

        XCTAssertEqual(
            getState(), expectedState,
            "Expected states to be equal but found \(getState())"
        )
    }

    func test_create_store_notifies_observers_about_state_change() throws {
        let initialState = CounterState(count: 0)
        var expectedState: CounterState?
        let observer = Observer<CounterState> { expectedState = $0 }

        let sut: StoreAPI<CounterState> = createStore
        let (dispatch, subscribe, getState) = sut(testReducer, initialState)
        _ = subscribe(observer)

        dispatch(TestAction.input)

        XCTAssertEqual(
            getState(), try XCTUnwrap(expectedState),
            "Expected states to be equal but found \(getState())"
        )
    }

    func test_create_store_unsubscribes_observers() throws {
        let initialState = CounterState(count: 0)
        var expectedState: CounterState?
        let observer = Observer<CounterState> { expectedState = $0 }

        let sut: StoreAPI<CounterState> = createStore
        let (dispatch, subscribe, getState) = sut(testReducer, initialState)
        let unsubscribe = subscribe(observer)

        dispatch(TestAction.input)
        unsubscribe()
        dispatch(TestAction.input)

        XCTAssertEqual(
            try XCTUnwrap(expectedState?.count), 1,
            "Expected count to have increased by 1, but got \(getState().count)"
        )
    }
}

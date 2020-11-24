//
//  TestsUtils.swift
//  fuduxTests
//
//  Created by Daniel Garcia
//

@testable import fudux

struct CounterState: Equatable {
    let count: Int
}

func testReducer(action: Action, state: inout CounterState) {
    switch action as! TestAction {
    case .input:
        state = CounterState(count: state.count + 1)
    }
}

enum TestAction: Action {
    case input
}

extension CounterState {
    static let initialState = CounterState(count: 0)
}

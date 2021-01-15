//
//  Observer.swift
//  fudux
//
//  Created by Daniel Garcia
//

public final class Observer<State> {
    public let newState: (State) -> Void

    public init(_ newState: @escaping (State) -> Void) {
        self.newState = newState
    }
}

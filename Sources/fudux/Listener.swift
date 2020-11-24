//
//  Listener.swift
//  fudux
//
//  Created by Daniel Garcia
//

public final class Listener<State> {
    public let updateTo: (State) -> Void

    public init(_ updateTo: @escaping (State) -> Void) {
        self.updateTo = updateTo
    }
}

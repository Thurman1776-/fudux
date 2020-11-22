//
//  createStore.swift
//  fudux
//
//  Created by Daniel Garcia
//

public protocol Action {}
public typealias DispatchFunction = (Action) -> Void
public typealias GetState<State> = () -> State
public typealias Subscribe<State> = (Listener<State>) -> () -> Void

public typealias StoreAPI<State> = (@escaping (Action, inout State) -> Void, State) -> (DispatchFunction, Subscribe<State>, GetState<State>)

public func createStore<State: Equatable>(
    reducer: @escaping (Action, inout State) -> Void,
    initialState: State
)
    -> (DispatchFunction, Subscribe<State>, GetState<State>)
{
    var state: State = initialState
    var listeners: [Listener<State>] = []
    var isDispatching = false

    func getState() -> State { state }

    func dispatch(action: Action) {
        guard !isDispatching else {
            fatalError("Reducers may not dispatch actions!")
        }

        isDispatching = true
        reducer(action, &state)
        isDispatching = false
        listeners.forEach { $0.updateTo(state) }
    }

    func subscribe(listener: Listener<State>) -> () -> Void {
        let unsubscribeFunction: () -> Void = {
            listeners = listeners.filter { $0 !== listener }
        }
        guard !isDispatching else {
            fatalError(
                """
                    You may not call store.subscribe() while the reducer is executing. 
                    If you would like to be notified after the store has been updated, subscribe from a
                    component and invoke store.getState() in the callback to access the latest state.
                """
            )
        }

        listeners.append(listener)
        return unsubscribeFunction
    }

    return (dispatch, subscribe, getState)
}

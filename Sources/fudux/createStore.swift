//
//  createStore.swift
//  fudux
//
//  Created by Daniel Garcia
//

public protocol Action {}
public typealias DispatchFunction = (Action) -> Void
public typealias GetState<State> = () -> State
public typealias Subscribe<State> = (Observer<State>) -> () -> Void
public typealias Reducer<State> = (Action, inout State) -> Void

public typealias StoreAPI<State> = (@escaping Reducer<State>, State) -> (DispatchFunction, Subscribe<State>, GetState<State>)

/// Creates a Redux store that holds the state tree.
/// The only way to change the data in the store is to call `dispatch()` on it.
///
/// There should only be a single store in your app.
/// - Parameters:
///   - reducer: reducer A function that returns the next state tree,
///   given the current state tree and the action to handle.
///   - initialState: The initial state.
/// - Returns: A Redux store that lets you read the state, dispatch actions and subscribe to changes.

public func createStore<State: Equatable>(
    reducer: @escaping (Action, inout State) -> Void,
    initialState: State
)
    -> (DispatchFunction, Subscribe<State>, GetState<State>)
{
    var state: State = initialState
    var observers: [Observer<State>] = []
    var isDispatching = false

    func getState() -> State { state }

    func dispatch(action: Action) {
        guard !isDispatching else {
            fatalError("Reducers may not dispatch actions!")
        }

        isDispatching = true
        reducer(action, &state)
        isDispatching = false
        observers.forEach { $0.newState(state) }
    }

    func subscribe(observer: Observer<State>) -> () -> Void {
        let unsubscribeFunction: () -> Void = {
            observers = observers.filter { $0 !== observer }
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

        observers.append(observer)
        return unsubscribeFunction
    }

    return (dispatch, subscribe, getState)
}

//
//  applyMiddleware.swift
//  fudux
//
//  Created by Daniel Garcia
//

public typealias HandleAction = (Action) -> Void
public typealias WrapDispatch = (Action) -> Void
public typealias Middleware<State> = (@escaping GetState<State>, @escaping DispatchFunction) -> (@escaping WrapDispatch) -> HandleAction
public typealias StoreEnhancer<State> = (@escaping StoreAPI<State>) -> StoreAPI<State>

/// /**
/// Creates a store enhancer that applies middleware to the dispatch method
/// of the Redux store. This is handy for a variety of tasks, such as expressing
/// asynchronous actions in a concise manner, or logging every action.
///
/// * Because middleware is potentially asynchronous, this should be the first
/// store enhancer in the composition chain.
///
/// * Note each middleware will be given the `dispatch` and `getState` functions
///
/// - Parameter middlewares: The middleware chain to be applied.
/// - Returns:  A store enhancer applying the middleware.
public func applyMiddleware<State>(middlewares: [Middleware<State>])
    -> StoreEnhancer<State>
{
    { createStore in { reducer, initialState in
        let (storeDispatch, storeSubscribe, storeGetState) = createStore(reducer, initialState)
        var patchedDispatch: DispatchFunction!

        func thunkDispatch(action: Action) {
            patchedDispatch(action)
        }

        patchedDispatch = middlewares
            .reversed()
            .reduce({ action in
                storeDispatch(action)
            }) { accDispatch, middleware in
                let wrapDispatch = middleware(storeGetState, thunkDispatch)
                let handleAction = wrapDispatch(accDispatch)
                return handleAction
            }

        return (patchedDispatch, storeSubscribe, storeGetState)
    }
    }
}

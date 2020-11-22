public typealias HandleAction = (Action) -> Void
public typealias WrapDispatch = (Action) -> Void
public typealias Middleware<State> = (@escaping GetState<State>, @escaping DispatchFunction) -> (@escaping WrapDispatch) -> HandleAction
public typealias StoreEnhancer<State> = (@escaping StoreAPI<State>) -> StoreAPI<State>

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

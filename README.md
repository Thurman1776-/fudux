# fudux

[![Build Status](https://app.bitrise.io/app/a3fd5d63f9b4374c/status.svg?token=w6IIOkPI93FA8KtKzYx5ZA&branch=main)](https://app.bitrise.io/app/a3fd5d63f9b4374c)

# Introduction

Fudux is a functional implementation of [Redux for JS](https://github.com/reactjs/redux) that lets you to write apps in an unidirectional way in Swift. 

There's abudance of information on Redux out there, so in case you're not familiar with Redux, I would recommend visiting [the official site](https://redux.js.org)

The whole implementation is just 2 functions: 
- [createStore function](https://github.com/Thurman1776-/fudux/blob/main/Sources/fudux/createStore.swift)
- [applyMiddleware function](https://github.com/Thurman1776-/fudux/blob/main/Sources/fudux/applyMiddleware.swift)

Those are the barebones you need to get started. 
There's a utility [compose function](https://github.com/Thurman1776-/fudux/blob/main/Sources/fudux/compose.swift) that allows you to enhance the store with custom functionality, such as logging, storing actions, running actions on a queue, etc. 


# Table of Contents

- [Installation](#installation)
- [Example](#example)
- [Understading the library](#understading-the-library)
- [Contributing](#contributing)
- [Credits](#credits)
- [Alternatives](#alternatives)

# Installation

⚠️ This repository only supports SPM. 
Alternatively, you can just copy the [createStore](https://github.com/Thurman1776-/fudux/blob/main/Sources/fudux/createStore.swift) & [applyMiddleware](https://github.com/Thurman1776-/fudux/blob/main/Sources/fudux/applyMiddleware.swift) required functions to your project. 

## Swift Package Manager

You can install fudux via [Swift Package Manager](https://swift.org/package-manager/) by adding the following line to your `Package.swift`:

```swift
import PackageDescription

let package = Package(
    [...]
    dependencies: [
        .package(url: "https://github.com/Thurman1776-/fudux", from: "1.0.0"),
    ]
)
```

# Example

# About fudux


Given a simple app that keeps track of a counter which can be increased and decreased, you could hold that state in a data type like so:

```swift
final class FuduxAppState: Equatable, ObservableObject {
    let count: Int
    
    init(count: Int) {
        self.count = count
    }
}
```

To express chages to such state, you would define actions. 
Let's declare two actions, one for increasing and one for decreasing the counter.

```swift
enum FuduxAction: Action {
    case increase
    case decrease
}
```

You mutate such state by dispatching actions to the store. A reducer responds to these actions:

```swift
func fuduxReducer(action: Action, state: inout FuduxAppState) {
    switch action as! FuduxAction { // Optionality here is handled by personal taste
    case .increase:
        state = FuduxAppState(count: state.count + 1)
    case .decrease:
        state = FuduxAppState(count: state.count - 1)
    }
}
```
By definition, a reducer should be a pure function (free of side effects). It receives the current app state and an action and computes a new app state.

What holds state & forwads actions to mutate such state, is called a Store. You create a store by doing: 

```swift
createStore(reducer: fuduxReducer, initialState: FuduxAppState(count: 0))
```

It is up to you how you want to keep the functions created by the Store around. This library isn't opinionated on how you should do that. 

For a quick & simple example, let's say you declare it at the top level of your program entry:

```swift
let (dispatch, subscribe, getState) = createStore(reducer: fuduxReducer, initialState: FuduxAppState(count: 0))

@main
struct IntegrateFuduxApp: App {
    @State
    private var appState = FuduxAppState(count: 0)
    @State
    private var unsubscribe: () -> Void = { }
    
    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
                .onAppear {
                    let listener = Listener<FuduxAppState> { appState = $0 }
                    unsubscribe = subscribe(listener)
                }
                .onDisappear {
                    unsubscribe()
                }
        }
    }
}
```
Where `ContentView` looks like the following: 

```swift
struct ContentView: View {
    @ObservedObject
    private var appState: FuduxAppState
    
    init(appState: FuduxAppState) {
        self.appState = appState
    }
    
    var body: some View {
        VStack {
            Text("Current count -> \(appState.count)!")
                .padding()
            Button("Tap to increase") {
                dispatch(FuduxAction.increase)
            }
            Button("Tap to decrease") {
                dispatch(FuduxAction.decrease)
            }
        }
    }
}
```

Note that `ContentView` is using indiscriminately the `dispatch` function originally declared in `IntegrateFuduxApp`. Again, do not take this as the way to establish these relationships, you're free to do whatever you want.  This is just for demonstration purposes.  


Whenever you tap on the `Tap to increase` or `Tap to decrease` buttons, they will emit corresponding actions. Such actions will go through to store & and its reducers. Because of the nature of SwiftUI, any change to `appState` in `IntegrateFuduxApp` will trigger a UI update. 

### Managing side effects

To describe & execute work that includes side effects, you can define middleware functions that can dispatch further actions upon sucess/failure. 

Given that you include an additional case statement in `FuduxAction` enum, let's call it `reset`, in your reducer you can just reset the current count: 

```swift
func fuduxReducer(action: Action, state: inout FuduxAppState) {
    // ... other cases handled already
    case .reset:
        state = FuduxAppState(count: 0)
    }
}
```

Then, define your custom function that retuns a middleware conforming to the same type your app state is, in this example, `FuduxAppState`. 

You return 3 closures: 
- First: takes the current app state function and a dispatch function
- Second: takes a function that refers to the next middleware in the chain, or the original store's dispatch if it is the last one. 
- Third: takes the dispatched action. This is what you would react to. 

Note: Ideally you inject entities to the function as a form of Dependency Injection.

```swift
func fuduxMiddleware(dispatchQueue: DispatchQueue) -> Middleware<FuduxAppState> {
    {
        getState, dispatchFunction in {
            next in {
                action in
                next(action)
                
                // When count reaches 3, the middleware resets the count property to zero after
                // 2 seconds
                if getState().count == 3 {
                    // Fire any heavy / long running task
                    dispatchQueue.asyncAfter(deadline: .now() + 2) {
                        dispatchFunction(FuduxAction.reset)
                    }
                }
            }
        }
    }
}
```

Next, you need to register such side effect. For this, you use the `applyMiddleware` function: 

```swift
let appliedMiddledwares = applyMiddleware(middlewares: [fuduxMiddleware(dispatchQueue: DispatchQueue.global())])
let composedStore = appliedMiddledwares(createStore)
let (dispatch, subscribe, getState) = composedStore(fuduxReducer, FuduxAppState(count: 0))
```

What this middleware ends up doing is, resetting the count to zero after 2 seconds when the state reaches 3. 

# Understading the library

In case you want to see how everything plays along together, have a look at the [integration tests](https://github.com/Thurman1776-/fudux/blob/main/Tests/fuduxTests/ReduxIntegrationTests.swift). They should provide a general overview of API usage.

# Contributing

-- TODO

# Credits

- Nothing here is new, all credit goes to [Dan Abramov](https://github.com/gaearon). I just translated the javascript implementation in Swift as closely as possible. No protocols nor inheritance, just plain simple functions. 

# Alternatives

Make sure to check out these other great alternatives that following the same principle: 

- [ReSwift](https://github.com/ReSwift/ReSwift)
- [Composable architecture by pointfreeco](https://github.com/pointfreeco/swift-composable-architecture)
 - [Fluxor](https://github.com/FluxorOrg/Fluxor)

# fudux

[![Build Status](https://app.bitrise.io/app/a3fd5d63f9b4374c/status.svg?token=w6IIOkPI93FA8KtKzYx5ZA&branch=main)](https://app.bitrise.io/app/a3fd5d63f9b4374c)

# Introduction

Fudux is a functional implementation of [Redux for JS](https://github.com/reactjs/redux) that lets you to write apps in an unidirectional way in Swift. 

There's abudance of information on Redux out there, so in case you're not familiar with Redux, I would recommend visiting [the official site](https://redux.js.org)

The whole implementation is just 2 functions: 
- [createStore function](https://github.com/Thurman1776-/fudux/blob/main/Sources/fudux/createStore.swift)
- [applyMiddleware function](https://github.com/Thurman1776-/fudux/blob/main/Sources/fudux/applyMiddleware.swift)

Those are the barebones you need to get started. There's a utility [compose function](https://github.com/Thurman1776-/fudux/blob/main/Sources/fudux/compose.swift) that lets chain these (and other APIs alike) functions together.  


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

### Introduce side effects

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

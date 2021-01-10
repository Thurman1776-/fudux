# fudux

[![Build Status](https://app.bitrise.io/app/a3fd5d63f9b4374c/status.svg?token=w6IIOkPI93FA8KtKzYx5ZA&branch=main)](https://app.bitrise.io/app/a3fd5d63f9b4374c)

# Introduction

Fudux is a functional implementation of [Redux for JS](https://github.com/reactjs/redux) that lets you to write apps in an unidirectional way in Swift. 

There's abudance of information on Redux out there, so in case you're not familiar with Redux, I would recommend visiting [the official site](https://redux.js.org)

The whole implementation is just 2 functions: 
- [createStore function](https://github.com/Thurman1776-/fudux/blob/main/Sources/fudux/createStore.swift)
- [applyMiddleware function](https://github.com/Thurman1776-/fudux/blob/main/Sources/fudux/applyMiddleware.swift)

Those are the barebones you need to get started. There's a utility [compose function](https://github.com/Thurman1776-/fudux/blob/main/Sources/fudux/compose.swift) that lets chain these (and other APIs alike)functions together.  


# Table of Contents

- [Installation](#installation)
- [Example](#demo)
- [Contributing](#contributing)
- [Credits](#credits)
- [Alternatives](#alternatives)



# Installation

⚠️ This repository only supports SPM

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

-- TODO -> Example


# Contributing

-- TODO -> How can people contribute?

# Credits

- Nothing here is new, all credit goes to [Dan Abramov](https://github.com/gaearon). I just translated the javascript implementation in Swift as closely as possible. 

# Alternatives

-- TODO -> List available Swift implementation options (ReSwift & Composable)

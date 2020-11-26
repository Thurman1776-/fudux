//
//  compose.swift
//  fudux
//
//  Created by Daniel Garcia
//

import Foundation

precedencegroup CompositionPrecedence {
    associativity: left
}

infix operator >>>: CompositionPrecedence

/// Composes single-argument functions from left to right.
/// - Parameters:
///   - lhs: First function that maps initial value to intermediate one
///   - rhs: Second function which bridges intermediate value to end result
/// - Returns: A function obtained by composing the argument functions
func >>> <T, U, V>(lhs: @escaping (T) -> U, rhs: @escaping (U) -> V) -> (T) -> V {
    return { initial in rhs(lhs(initial)) }
}


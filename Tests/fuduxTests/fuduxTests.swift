import XCTest
@testable import fudux

final class fuduxTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(fudux().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

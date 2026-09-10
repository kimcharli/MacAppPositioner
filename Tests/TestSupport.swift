//
// Shared assertion helpers for compiled tests.
//
// Compiled into each test binary by `run_compiled_test` in Scripts/test_all.sh,
// alongside MacAppPositioner/Shared/*.swift and the test file itself.
//
// Deliberately tiny: this exists so test files don't each carry their own copy
// of the same pass/fail bookkeeping. If full Xcode is ever installed, this is
// the layer that XCTest replaces — see docs/REMEDIATION-PLAN-2026-09-10.md.

import Foundation

/// Collects failures across a test run so every assertion reports, rather than
/// aborting at the first one.
final class TestRunner {
    private(set) var failures: [String] = []
    private let name: String

    init(_ name: String) {
        self.name = name
        print("=== \(name) ===")
    }

    /// Prints a section heading.
    func section(_ title: String) {
        print("\n\(title)")
    }

    /// Records one assertion. `detail` is only evaluated on failure.
    func check(_ condition: Bool, _ label: String, _ detail: @autoclosure () -> String = "") {
        if condition {
            print("  ✅ \(label)")
        } else {
            let extra = detail()
            print("  ❌ \(label)\(extra.isEmpty ? "" : " — \(extra)")")
            failures.append(label)
        }
    }

    /// Convenience for equality assertions, which report both sides on failure.
    func checkEqual<T: Equatable>(_ actual: T, _ expected: T, _ label: String) {
        check(actual == expected, label, "expected \(expected), got \(actual)")
    }

    /// Prints the summary and exits with 0 (all passed) or 1 (any failed).
    func finish() -> Never {
        print("\n=== \(name): \(failures.isEmpty ? "PASS" : "FAIL") ===")
        if !failures.isEmpty {
            print("Failed assertions:")
            failures.forEach { print("  - \($0)") }
        }
        exit(failures.isEmpty ? 0 : 1)
    }
}

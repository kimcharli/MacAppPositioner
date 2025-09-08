#!/usr/bin/env swift

import AppKit
import Foundation

/**
 * Real Positioning Test
 * Tests actual window positioning by analyzing MacAppPositioner debug output
 * This catches bugs where coordinate math is correct but positioning fails
 */

print("=== Real Positioning Test ===")

var allTestsPass = true

// Test 1: Run MacAppPositioner apply with debug output
print("\n🧪 Test 1: MacAppPositioner Apply Debug Analysis")

let task = Process()
task.launchPath = "/bin/bash" 
task.arguments = ["-c", "./MacAppPositioner/MacAppPositioner apply home --debug 2>&1"]

let pipe = Pipe()
task.standardOutput = pipe
task.standardError = pipe
task.launch()
task.waitUntilExit()

let data = pipe.fileHandleForReading.readDataToEndOfFile()
let output = String(data: data, encoding: .utf8) ?? ""

print("Debug output analysis:")
print(String(repeating: "-", count: 40))

// Test 2: Parse debug output for positioning failures
print("\n🧪 Test 2: Position Change Analysis")

let lines = output.components(separatedBy: .newlines)
var positioningResults: [(app: String, target: CGPoint, final: CGPoint, success: Bool)] = []

var currentApp = ""
var targetPos = CGPoint.zero
var finalPos = CGPoint.zero

for line in lines {
    // Extract application being processed
    if line.contains("Processing") && line.contains("for position") {
        let parts = line.components(separatedBy: " ")
        if let appIndex = parts.firstIndex(of: "Processing") {
            currentApp = parts[appIndex + 1]
        }
    }
    
    // Extract target position
    if line.contains("Target position:") {
        if let range = line.range(of: "Target: (") {
            let posStr = String(line[range.upperBound...])
            if let endRange = posStr.range(of: ",") {
                let xStr = String(posStr[..<endRange.lowerBound])
                let remaining = String(posStr[endRange.upperBound...])
                if let yEndRange = remaining.range(of: ",") {
                    let yStr = String(remaining[..<yEndRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                    if let x = Double(xStr), let y = Double(yStr) {
                        targetPos = CGPoint(x: x, y: y)
                    }
                }
            }
        }
    }
    
    // Extract final position
    if line.contains("Final position:") {
        if let range = line.range(of: "Final: (") {
            let posStr = String(line[range.upperBound...])
            if let endRange = posStr.range(of: ",") {
                let xStr = String(posStr[..<endRange.lowerBound])
                let remaining = String(posStr[endRange.upperBound...])
                if let yEndRange = remaining.range(of: ",") {
                    let yStr = String(remaining[..<yEndRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                    if let x = Double(xStr), let y = Double(yStr) {
                        finalPos = CGPoint(x: x, y: y)
                        
                        // Check if positioning succeeded (positions should be close)
                        let deltaX = abs(finalPos.x - targetPos.x)
                        let deltaY = abs(finalPos.y - targetPos.y)
                        let success = deltaX < 10 && deltaY < 10  // Within 10 pixels
                        
                        positioningResults.append((
                            app: currentApp,
                            target: targetPos,
                            final: finalPos,
                            success: success
                        ))
                    }
                }
            }
        }
    }
}

// Test 3: Analyze positioning results
print("\n🧪 Test 3: Positioning Accuracy Analysis")

var allPositioningSuccessful = true

for result in positioningResults {
    print("  \(result.app):")
    print("    Target:  (\(result.target.x), \(result.target.y))")
    print("    Final:   (\(result.final.x), \(result.final.y))")
    
    if result.success {
        print("    Result: ✅ POSITIONED CORRECTLY")
    } else {
        print("    Result: ❌ POSITIONING FAILED")
        let deltaX = result.final.x - result.target.x
        let deltaY = result.final.y - result.target.y
        print("    Delta:   (\(deltaX), \(deltaY))")
        allPositioningSuccessful = false
    }
}

allTestsPass = allTestsPass && allPositioningSuccessful

// Test 4: Check for builtin monitor positioning (negative Y indicates builtin)
print("\n🧪 Test 4: Monitor Target Validation")

for result in positioningResults {
    let onBuiltin = result.final.y < 0  // Negative Y means builtin monitor
    let shouldBeOnPrimary = true  // According to config, apps should be on primary (4K)
    
    print("  \(result.app):")
    if onBuiltin && shouldBeOnPrimary {
        print("    ❌ On builtin monitor (Y=\(result.final.y)) but should be on primary")
        allTestsPass = false
    } else if !onBuiltin {
        print("    ✅ On primary monitor (Y=\(result.final.y))")
    }
}

// Overall Result
print("\n" + String(repeating: "=", count: 40))
print("🏁 REAL POSITIONING TEST RESULT")
print(String(repeating: "=", count: 40))

print("Final Result: \(allTestsPass ? "✅ ALL TESTS PASS" : "❌ SOME TESTS FAILED")")

if allTestsPass {
    print("\n✅ Real positioning is working correctly!")
    print("   Windows are being positioned on the correct monitors.")
} else {
    print("\n❌ Real positioning issues detected!")
    print("   Windows are not being positioned correctly.")
    print("   This indicates a bug in the Accessibility API positioning code.")
}

exit(allTestsPass ? 0 : 1)
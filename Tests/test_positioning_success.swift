#!/usr/bin/env swift

import AppKit
import Foundation

/**
 * Positioning Success Validation
 * Runs apply command and validates that coordinate conversion is working
 */

print("=== Positioning Success Validation ===")

var allTestsPass = true

// Test 1: Run apply command and capture output
print("\n🧪 Test 1: Apply Command Execution")

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

print("Apply command exit code: \(task.terminationStatus)")
let applySuccess = task.terminationStatus == 0
print("Apply command result: \(applySuccess ? "✅ SUCCESS" : "❌ FAILED")")

if !applySuccess {
    print("Apply command output:")
    print(output)
    allTestsPass = false
}

// Test 2: Check if coordinate conversion is working (no warning messages)
print("\n🧪 Test 2: Coordinate Conversion Analysis")

let lines = output.components(separatedBy: .newlines)
var conversionWarnings = 0
var conversionSuccesses = 0

for line in lines {
    if line.contains("⚠️  Global canonical point") && line.contains("not found in any monitor") {
        conversionWarnings += 1
        print("  ❌ Conversion warning: \(line)")
    }
    if line.contains("Successfully moved") {
        conversionSuccesses += 1
        print("  ✅ Successful move detected")
    }
}

print("Conversion warnings: \(conversionWarnings)")
print("Successful moves: \(conversionSuccesses)")

if conversionWarnings > 0 {
    print("  ❌ Coordinate conversion issues detected")
    allTestsPass = false
} else {
    print("  ✅ No coordinate conversion warnings")
}

if conversionSuccesses > 0 {
    print("  ✅ Successful positioning operations detected")
} else {
    print("  ⚠️  No successful positioning operations detected")
}

// Test 3: Parse positioning results for target vs final validation
print("\n🧪 Test 3: Target vs Final Position Validation")

var positioningAttempts = 0
var positioningSuccesses = 0

var currentApp = ""
var targetPos = CGPoint.zero
var finalPos = CGPoint.zero

for line in lines {
    // Extract application being processed
    if line.contains("Processing") && line.contains("for position") {
        let parts = line.components(separatedBy: " ")
        if let appIndex = parts.firstIndex(of: "Processing") {
            currentApp = parts[appIndex + 1]
            positioningAttempts += 1
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
                        
                        if success {
                            positioningSuccesses += 1
                        }
                        
                        print("  \(currentApp):")
                        print("    Target: (\(targetPos.x), \(targetPos.y))")
                        print("    Final:  (\(finalPos.x), \(finalPos.y))")
                        print("    Result: \(success ? "✅ SUCCESS" : "❌ FAILED")")
                        
                        // Check monitor targeting
                        let targetOnPrimary = targetPos.y >= 0  // Primary monitor has Y >= 0 in our setup
                        let finalOnPrimary = finalPos.y >= 0
                        
                        if targetOnPrimary == finalOnPrimary {
                            print("    Monitor: ✅ Correct target monitor")
                        } else {
                            print("    Monitor: ❌ Wrong target monitor")
                            allTestsPass = false
                        }
                    }
                }
            }
        }
    }
}

print("\nPositioning summary:")
print("  Attempts: \(positioningAttempts)")
print("  Successes: \(positioningSuccesses)")

let successRate = positioningAttempts > 0 ? Double(positioningSuccesses) / Double(positioningAttempts) : 0.0
print("  Success rate: \(Int(successRate * 100))%")

if successRate >= 0.8 {  // At least 80% success rate
    print("  ✅ Good positioning success rate")
} else {
    print("  ❌ Poor positioning success rate")
    allTestsPass = false
}

// Overall Result
print("\n" + String(repeating: "=", count: 40))
print("🏁 POSITIONING SUCCESS VALIDATION")
print(String(repeating: "=", count: 40))

print("Final Result: \(allTestsPass ? "✅ ALL TESTS PASS" : "❌ SOME TESTS FAILED")")

if allTestsPass {
    print("\n✅ Positioning fix is working correctly!")
    print("   - Apply command executes successfully")
    print("   - Coordinate conversion works without warnings")
    print("   - Windows are positioned on correct monitors")
} else {
    print("\n❌ Positioning issues still detected!")
    print("   Review the test results above for details.")
}

exit(allTestsPass ? 0 : 1)
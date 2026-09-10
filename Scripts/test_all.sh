#!/bin/bash

# Mac App Positioner - Test Suite
# Runs the read-only coordinate/detection tests in Tests/.
#
# Run from the repository root:  ./Scripts/test_all.sh

set -uo pipefail

echo "🧪 Mac App Positioner - Test Suite"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Run a test script and record the result.
# Note: uses `X=$((X + 1))` rather than `((X++))`, which returns a non-zero
# exit status when the pre-increment value is 0 and can abort the script.
run_test() {
    local test_name="$1"
    local test_script="$2"

    echo -e "\n${BLUE}🔬 Running: ${test_name}${NC}"
    echo "----------------------------------------"

    if [ ! -f "$test_script" ]; then
        echo -e "${RED}❌ ${test_name}: MISSING (${test_script})${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("${test_name} (missing)")
        return
    fi

    if swift "$test_script"; then
        echo -e "${GREEN}✅ ${test_name}: PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ ${test_name}: FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_name")
    fi
}

if ! command -v swift &> /dev/null; then
    echo -e "${RED}❌ Error: Swift compiler not found${NC}"
    echo "   Please install Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

echo -e "${YELLOW}Starting coordinate system validation tests...${NC}"

run_test "Screen Detection"          "Tests/test_screen_detection.swift"
run_test "Main Screen Reference"     "Tests/test_main_screen.swift"
run_test "Monitor Detection"         "Tests/test_monitor_detection.swift"
run_test "Visible Frames"            "Tests/test_visible_frames.swift"
run_test "App Screen Detection"      "Tests/test_app_screen_detection.swift"
run_test "Positioning Logic"         "Tests/test_positioning_logic.swift"
run_test "Real Positioning"          "Tests/test_real_positioning.swift"

# Deliberately excluded from the suite:
#
#   Tests/test_chrome_simple.swift
#     Moves real Chrome windows and asserts against a 1329px-tall display
#     belonging to the original author. Cannot pass on other hardware.
#
#   Tests/test_positioning_success.swift
#     Shells out to ./MacAppPositioner/MacAppPositioner (a stale path; the
#     binary is built to dist/) and invokes a real `apply`, which requires a
#     configured profile and moves the operator's windows.
#
# Both are superseded by the fixture-based XCTest target planned in Phase 2 of
# docs/REMEDIATION-PLAN-2026-09-10.md rather than repaired in place.

echo ""
echo "=================================================="
echo -e "${BLUE}🏁 TEST SUITE RESULTS${NC}"
echo "=================================================="

echo "Tests Passed: ${TESTS_PASSED}"
echo "Tests Failed: ${TESTS_FAILED}"

if [ "${TESTS_FAILED}" -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo -e "${GREEN}✅ Coordinate system is working correctly${NC}"
    exit 0
fi

echo -e "\n${RED}⚠️  SOME TESTS FAILED!${NC}"
echo -e "\n${YELLOW}Failed Tests:${NC}"
for test in "${FAILED_TESTS[@]}"; do
    echo -e "${RED}  - ${test}${NC}"
done

echo -e "\n${YELLOW}Recommended Actions:${NC}"
echo "1. Review the failed test output above"
echo "2. Check coordinate system implementation"
echo "3. Verify monitor detection logic"
echo "4. Confirm Accessibility permission is granted to your terminal"

exit 1

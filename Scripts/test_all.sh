#!/bin/bash

# Mac App Positioner - Comprehensive Test Suite
# Runs all coordinate system validation tests to detect issues early

set -e  # Exit on any error

echo "🧪 Mac App Positioner - Comprehensive Test Suite"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_script="$2"
    
    echo -e "\n${BLUE}🔬 Running: $test_name${NC}"
    echo "----------------------------------------"
    
    if swift "$test_script"; then
        echo -e "${GREEN}✅ $test_name: PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ $test_name: FAILED${NC}"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
    fi
}

# Check if Swift is available
if ! command -v swift &> /dev/null; then
    echo -e "${RED}❌ Error: Swift compiler not found${NC}"
    echo "   Please install Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

# Run all tests
echo -e "${YELLOW}Starting coordinate system validation tests...${NC}\n"

# Test 1: Simple coordinate system test (fast and reliable)
run_test "Simple Coordinate System Test" "test_coordinate_system_simple.swift"

# Test 2: Comprehensive coordinate system test
run_test "Comprehensive Coordinate System" "test_coordinate_system_comprehensive.swift"

# Test 3: Window positioning integration test
run_test "Window Positioning Integration" "test_positioning_integration.swift"

# Test 4: Canonical coordinate validation
run_test "Canonical Coordinate Validation" "test_canonical_coordinate_validation.swift"

# Test 5: Real positioning test (validates coordinate conversion fix)
run_test "Real Positioning Validation" "test_real_positioning.swift"

# Test 4: Original coordinate test (if exists)
if [ -f "test_canonical_coordinates.swift" ]; then
    run_test "Original Canonical Coordinates" "test_canonical_coordinates.swift"
fi

# Test 5: Monitor detection test (if exists)  
if [ -f "test_monitor_detection.swift" ]; then
    run_test "Monitor Detection" "test_monitor_detection.swift"
fi

# Overall results
echo -e "\n${'='*50}"
echo -e "${BLUE}🏁 TEST SUITE RESULTS${NC}"
echo -e "${'='*50}"

echo "Tests Passed: ${TESTS_PASSED}"
echo "Tests Failed: ${TESTS_FAILED}"

if [ ${TESTS_FAILED} -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo -e "${GREEN}✅ Coordinate system is working correctly${NC}"
    echo -e "${GREEN}✅ Ready for development and deployment${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  SOME TESTS FAILED!${NC}"
    echo -e "${RED}❌ Coordinate system issues detected${NC}"
    
    echo -e "\n${YELLOW}Failed Tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "${RED}  - $test${NC}"
    done
    
    echo -e "\n${YELLOW}Recommended Actions:${NC}"
    echo "1. Review the failed test output above"
    echo "2. Check coordinate system implementation"
    echo "3. Verify monitor detection logic"
    echo "4. Validate configuration files"
    echo "5. Fix issues before proceeding with development"
    
    exit 1
fi
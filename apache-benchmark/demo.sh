#!/bin/bash
# Simple benchmark script example for demonstration
# This script shows how to use Apache Benchmark commands

echo "Apache Benchmark Demo Script"
echo "=========================="
echo

# Check if ab is installed
if ! command -v ab &> /dev/null; then
    echo "Error: Apache Benchmark (ab) is not installed."
    echo "Please install it using the instructions in README.md"
    exit 1
fi

echo "Apache Benchmark version:"
ab -V | head -1
echo

# Example target - you can change this to your own server
TARGET_URL=${1:-"http://httpbin.org/get"}
echo "Target URL: $TARGET_URL"
echo

echo "Running light benchmark test..."
echo "Command: ab -n 10 -c 2 -k $TARGET_URL"
echo "----------------------------------------"
ab -n 10 -c 2 -k "$TARGET_URL"

echo
echo "Demo completed!"
echo "For more advanced usage, refer to the README.md file."
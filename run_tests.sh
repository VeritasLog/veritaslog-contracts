#!/bin/bash

echo "🧪 Running VeritasLog Tests..."
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
sui move clean

# Build the project
echo "🔨 Building project..."
sui move build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    
    # Run tests
    echo "🚀 Running tests..."
    sui move test --verbose
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ All tests passed!"
    else
        echo ""
        echo "❌ Some tests failed!"
        exit 1
    fi
else
    echo "❌ Build failed!"
    exit 1
fi
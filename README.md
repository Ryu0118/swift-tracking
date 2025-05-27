# Tracking

A Swift property wrapper that caches computation results and recomputes only when tracked values change.

## Overview

`Tracking` is a simple Swift library that helps avoid redundant computations by caching results until the underlying values change.

## Features

- Cache computation results automatically
- Recompute only when tracked values change
- Track multiple values at once
- SwiftUI compatible

## Requirements

- Swift 6.0+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/swift-tracking.git", from: "0.1.0")
]
```

## Usage

### Basic Usage

```swift
import Tracking

@Tracking var data = [1, 2, 3, 4, 5]

// This computation will be cached
let result = recomputeWhen(didSet: $data) {
    return data.map { $0 * $0 }.reduce(0, +)
}

print(result) // Computes: 55

// Calling again returns cached result
let cachedResult = recomputeWhen(didSet: $data) {
    return data.map { $0 * $0 }.reduce(0, +)
}

print(cachedResult) // Returns cached: 55

// Changing data invalidates cache
data.append(6)

let newResult = recomputeWhen(didSet: $data) {
    return data.map { $0 * $0 }.reduce(0, +)
}

print(newResult) // Recomputes: 91
```

### Multiple Values

```swift
@Tracking var width = 100.0
@Tracking var height = 200.0

let area = recomputeWhen(didSet: $width, $height) {
    return width * height
}

print(area) // 20000.0
```

### SwiftUI

```swift
import SwiftUI
import Tracking

struct ContentView: View {
    @Tracking var items = Array(1...1000)

    var body: some View {
        Text("Sum: \(expensiveSum)")
    }

    private var expensiveSum: Int {
        recomputeWhen(didSet: $items) {
            return items.reduce(0, +)
        }
    }
}
```

## Benchmarks

To verify the performance benefits of caching, you can run the included benchmarks:

```bash
swift run -c release TrackingBenchmarks
```

The benchmarks compare computation times with and without tracking for:
- Fibonacci calculation (recursive)
- Array sum of squares
- Prime factorization
- Multiple dependencies
- Complex object processing

Expected results: Tracking shows significant performance improvements when the same computation is repeated multiple times, as it avoids redundant calculations by using cached results.

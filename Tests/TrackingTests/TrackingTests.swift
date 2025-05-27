import Testing
@testable import Tracking

@Test("Tracking initialization")
func trackingInitialization() {
    let tracking = Tracking(wrappedValue: 42)
    #expect(tracking.wrappedValue == 42)
}

@Test("Wrapped value getter and setter")
func wrappedValueGetterSetter() {
    var tracking = Tracking(wrappedValue: "initial")
    #expect(tracking.wrappedValue == "initial")

    tracking.wrappedValue = "updated"
    #expect(tracking.wrappedValue == "updated")
}

@Test("Projected value access")
func projectedValue() {
    let tracking = Tracking(wrappedValue: 100)
    let projected = tracking.projectedValue
    #expect(projected.wrappedValue == 100)
}

@Test("Basic cache functionality")
func cacheBasicFunctionality() {
    var callCount = 0
    @Tracking var value = 10

    let result1 = recomputeWhen(didSet: $value) {
        callCount += 1
        return value * 2
    }
    #expect(result1 == 20)
    #expect(callCount == 1)

    let result2 = recomputeWhen(didSet: $value) {
        callCount += 1
        return value * 2
    }
    #expect(result2 == 20)
    #expect(callCount == 1)
}

@Test("Cache invalidation on value change")
func cacheInvalidationOnValueChange() {
    var callCount = 0
    @Tracking var value = 5

    let result1 = recomputeWhen(didSet: $value) {
        callCount += 1
        return value * 3
    }
    #expect(result1 == 15)
    #expect(callCount == 1)

    value = 7

    let result2 = recomputeWhen(didSet: $value) {
        callCount += 1
        return value * 3
    }
    #expect(result2 == 21)
    #expect(callCount == 2)
}

@Test("Cache with multiple tracking values")
func cacheWithMultipleTrackingValues() {
    var callCount = 0
    @Tracking var value1 = 2
    @Tracking var value2 = 3

    let result1 = recomputeWhen(didSet: $value1, $value2) {
        callCount += 1
        return value1 + value2
    }
    #expect(result1 == 5)
    #expect(callCount == 1)

    let result2 = recomputeWhen(didSet: $value1, $value2) {
        callCount += 1
        return value1 + value2
    }
    #expect(result2 == 5)
    #expect(callCount == 1)

    value1 = 4

    let result3 = recomputeWhen(didSet: $value1, $value2) {
        callCount += 1
        return value1 + value2
    }
    #expect(result3 == 7)
    #expect(callCount == 2)
}

@Test("Cache isolation between functions")
func cacheIsolationBetweenFunctions() {
    @Tracking var value = 10
    var callCount = 0

    func function1() -> Int {
        return recomputeWhen(didSet: $value) {
            callCount += 1
            return value * 2
        }
    }

    func function2() -> Int {
        return recomputeWhen(didSet: $value) {
            callCount += 1
            return value * 2
        }
    }

    let result1 = function1()
    #expect(result1 == 20)
    #expect(callCount == 1)

    let result2 = function2()
    #expect(result2 == 20)
    #expect(callCount == 2)

    let result3 = function1()
    #expect(result3 == 20)
    #expect(callCount == 2)
}

@Test("Tracking Equatable conformance")
func trackingEquatable() {
    let tracking1 = Tracking(wrappedValue: 42)
    let tracking2 = Tracking(wrappedValue: 42)
    let tracking3 = Tracking(wrappedValue: 43)

    #expect(tracking1 == tracking2)
    #expect(tracking1 != tracking3)
}

@Test("Tracking Hashable conformance")
func trackingHashable() {
    let tracking1 = Tracking(wrappedValue: "test")
    let tracking2 = Tracking(wrappedValue: "test")
    let tracking3 = Tracking(wrappedValue: "different")

    #expect(tracking1.hashValue == tracking2.hashValue)
    #expect(tracking1.hashValue != tracking3.hashValue)
}

@Test("Tracking with complex types")
func trackingWithComplexTypes() {
    struct TestStruct: Equatable, Sendable {
        let id: Int
        let name: String
    }

    @Tracking var data = TestStruct(id: 1, name: "test")
    var callCount = 0

    let result1 = recomputeWhen(didSet: $data) {
        callCount += 1
        return "\(data.id):\(data.name)"
    }
    #expect(result1 == "1:test")
    #expect(callCount == 1)

    let result2 = recomputeWhen(didSet: $data) {
        callCount += 1
        return "\(data.id):\(data.name)"
    }
    #expect(result2 == "1:test")
    #expect(callCount == 1)

    data = TestStruct(id: 2, name: "updated")

    let result3 = recomputeWhen(didSet: $data) {
        callCount += 1
        return "\(data.id):\(data.name)"
    }
    #expect(result3 == "2:updated")
    #expect(callCount == 2)
}

@Test("Expensive computation caching")
func expensiveComputationCaching() {
    @Tracking var input = Array(1...100)
    var computationCount = 0

    func expensiveComputation() -> Int {
        computationCount += 1
        return input.reduce(0) { result, value in
            return result + value * value
        }
    }

    let result1 = recomputeWhen(didSet: $input) {
        return expensiveComputation()
    }
    #expect(computationCount == 1)

    let result2 = recomputeWhen(didSet: $input) {
        return expensiveComputation()
    }
    #expect(result1 == result2)
    #expect(computationCount == 1)

    input.append(101)

    let result3 = recomputeWhen(didSet: $input) {
        return expensiveComputation()
    }
    #expect(result1 != result3)
    #expect(computationCount == 2)
}

@Test("Empty tracking list")
func emptyTrackingList() {
    var callCount = 0
}

@Test("Nil values handling")
func nilValues() {
    @Tracking var optionalValue: String? = nil
    var callCount = 0

    let result1 = recomputeWhen(didSet: $optionalValue) {
        callCount += 1
        return optionalValue ?? "default"
    }
    #expect(result1 == "default")
    #expect(callCount == 1)

    let result2 = recomputeWhen(didSet: $optionalValue) {
        callCount += 1
        return optionalValue ?? "default"
    }
    #expect(result2 == "default")
    #expect(callCount == 1)

    optionalValue = "actual"

    let result3 = recomputeWhen(didSet: $optionalValue) {
        callCount += 1
        return optionalValue ?? "default"
    }
    #expect(result3 == "actual")
    #expect(callCount == 2)
}

@Test("Memory cleanup on cache invalidation")
func memoryCleanuOnCacheInvalidation() {
    @Tracking var value = Array(1...1000)

    let result1 = recomputeWhen(didSet: $value) {
        return value.count
    }
    #expect(result1 == 1000)

    value = Array(1...500)

    let result2 = recomputeWhen(didSet: $value) {
        return value.count
    }
    #expect(result2 == 500)
}

@Test("Exception safety in computation")
func exceptionSafetyInComputation() throws {
    @Tracking var value = 10
    var shouldThrow = false

    let result1 = recomputeWhen(didSet: $value) {
        if shouldThrow {
            fatalError("Should not throw here")
        }
        return value * 2
    }
    #expect(result1 == 20)

    shouldThrow = true

    #expect(throws: Never.self) {
        let _ = recomputeWhen(didSet: $value) {
            return value * 2
        }
    }
}

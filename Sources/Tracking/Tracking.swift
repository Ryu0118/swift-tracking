import SwiftUI

/// A property wrapper that tracks mutations of a value and provides caching for computed values.
///
/// Use this wrapper to optimize expensive computations by caching results and recomputing only when the wrapped
/// value changes. The cache storage is copy-on-write so that each instance maintains its own cache.
@propertyWrapper
public struct Tracking<Value>: DynamicProperty {
    /// The underlying value being wrapped and tracked.
    private var base: Value
    /// Internal cache storage to hold computed results per context.
    private var cacheStorage: Cache

    /// Creates a new `Tracking` wrapper with an initial wrapped value.
    ///
    /// - Parameter wrappedValue: The initial value to wrap and track.
    public init(wrappedValue: Value) {
        base = wrappedValue
        cacheStorage = Cache()
    }

    /// The value that this wrapper manages.
    ///
    /// Setting this value invalidates the cache for existing computed results.
    public var wrappedValue: Value {
        get {
            base
        }
        set {
            // Copy-on-write: if storage is shared, create a new cache; otherwise clear existing.
            if !isKnownUniquelyReferenced(&cacheStorage) {
                cacheStorage = Cache()
            } else {
                cacheStorage.getterCaches.removeAll()
            }
            base = newValue
        }
    }

    /// Provides access to the property wrapper instance via the `$` syntax.
    public var projectedValue: Self {
        self
    }

    /// Retrieves a cached value for a specific file and function key.
    ///
    /// - Parameters:
    ///   - file: The file path where the computation is invoked.
    ///   - function: The function name where the computation is invoked.
    /// - Returns: An optional cached result wrapped in `AnySendable`, or `nil` if not cached.
    fileprivate func getCachedValue(
        _ file: String,
        _ function: String
    ) -> AnySendable? {
        cacheStorage.getterCaches[file + function]
    }

    /// Stores a computed value in the cache for a specific file and function key.
    ///
    /// - Parameters:
    ///   - value: The result to cache, wrapped in `AnySendable`.
    ///   - file: The file path where the computation is invoked.
    ///   - function: The function name where the computation is invoked.
    fileprivate func setCachedValue(
        _ value: AnySendable,
        _ file: String,
        _ function: String
    ) {
        cacheStorage.getterCaches.updateValue(
            value,
            forKey: file + function
        )
    }

    /// Internal class that manages the cache storage. Uses copy-on-write semantics.
    private class Cache: @unchecked Sendable {
        /// Dictionary of cached results keyed by file+function string.
        var getterCaches: [String: AnySendable]

        /// Creates a new, empty cache storage.
        init(getterCaches: [String: AnySendable] = [:]) {
            self.getterCaches = getterCaches
        }
    }
}

/// Executes a closure and caches its result for given tracked values, recomputing only when those values change.
///
/// - Parameters:
///   - didSet: A variadic list of `Tracking` wrappers whose changes invalidate the cache.
///   - body: A closure whose result should be cached.
///   - file: The file path used as part of the cache key (defaults to #file).
///   - function: The function name used as part of the cache key (defaults to #function).
/// - Returns: The cached or newly computed result of type `Return`.
public func recomputeWhen<each V, Return: Sendable>(
    didSet: repeat Tracking<each V>,
    body: () -> Return,
    file: String = #file,
    function: String = #function
) -> Return {
    // Attempts to retrieve cached values for all tracking instances.
    func getCachedValue(from tracking: Tracking<some Any>, result: inout Return?) throws {
        if let cachedValue = tracking.getCachedValue(file, function)?.base as? Return {
            if result == nil {
                result = cachedValue
            }
        } else {
            throw NSError()
        }
    }

    // Stores the computed result in the cache for each tracking instance.
    func setCachedValue(tracking: Tracking<some Any>, value: Return) {
        tracking.setCachedValue(AnySendable(value), file, function)
    }

    do {
        var cachedValue: Return?
        // Try to fetch caches; if all succeed, return the cached value.
        repeat try getCachedValue(from: each didSet, result: &cachedValue)
        return cachedValue!
    } catch {
        // If any cache is missing, compute the result and store it.
        let result = body()
        repeat setCachedValue(tracking: each didSet, value: result)
        return result
    }
}

extension Tracking: Equatable where Value: Equatable {
    /// Equates two `Tracking` wrappers based on their underlying values.
    public static func == (lhs: Tracking<Value>, rhs: Tracking<Value>) -> Bool {
        lhs.base == rhs.base
    }
}

extension Tracking: Hashable where Value: Hashable {
    /// Hashes the underlying wrapped value.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(base)
    }
}

/// A type-erased wrapper for `Sendable` values, enabling caching of arbitrary results.
///
/// Use this to wrap any `Sendable` result before storing it in the cache.
struct AnySendable: @unchecked Sendable {
    /// The underlying value stored.
    let base: Any

    /// Creates an `AnySendable` wrapping a `Sendable` value.
    ///
    /// - Parameter base: The sendable value to store.
    @inlinable
    init(_ base: some Sendable) {
        self.base = base
    }
}

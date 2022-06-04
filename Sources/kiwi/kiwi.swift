@usableFromInline
internal typealias Arr = ContiguousArray

/// Holds variables for kiwi
public struct Kiwi {
    /// Initial capicity of all arrays
    public static var arrayCap: Int = 32
    public static var printMemoryLayout: Bool = false
    @usableFromInline
    internal static var enumCases: [String: Int] = [:]
    @usableFromInline
    internal static var caseCounter: Int = 0
}

/// Holds a pointer to an array.
///
/// Use the `get` method to get the element of the array at the specified index
public struct UnsafePointerArraySlice<T> {
    private let ptr: UnsafeBufferPointer<T>
    private let start: Int
    
    @inline(__always)
    public func get(_ i: Int) -> T {
        return self.ptr[self.start + i]
    }
    
    init(_ ptr: UnsafeBufferPointer<T>, start: Int) {
        self.ptr = ptr
        self.start = start
    }
}

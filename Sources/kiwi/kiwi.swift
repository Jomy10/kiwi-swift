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
    @usableFromInline
    let ptr: UnsafeBufferPointer<T>
    @usableFromInline
    let start: Int
    
    @available(*, deprecated, message: "Use subscript instead")
    @inlinable
    public func get(_ i: Int) -> T {
        return self.ptr[self.start + i]
    }
    
    @inlinable 
    public subscript(_ i: Int) -> T {
        return self.ptr[self.start + i]
    }
    
    @inlinable
    internal init(_ ptr: UnsafeBufferPointer<T>, start: Int) {
        self.ptr = ptr
        self.start = start
    }
}

//===================//
// methods for tests //
//===================//

#if DEBUG
internal extension World {
    func getComponents() -> ComponentStore<ComponentType> { self.components }
    func getEntities() -> EntityStore<EntityDataType, FlagType> { self.entities }
    func getEntityPool() -> Arr<Entity> { self.entityPool }
}
#endif

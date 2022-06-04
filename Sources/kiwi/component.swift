/// Enums containing components should conform to this protocol
public protocol ComponentCollection {
    /// Returns the amount of cases of the enum
    @inlinable
    static var count: Int { get }
    /// Returns the id of  component`c`
    @inlinable
    static func id(_ c: Self) -> Int
    /// Returs the id of this component
    @inlinable
    var id: Int { get }
}

public extension ComponentCollection {
    @inlinable
    var id: Int { return Self.id(self) }
}

//=====================================================================

/// Component store holds all components in the world
@usableFromInline
internal struct ComponentStore<ComponentType: ComponentCollection> {
    /// Amount of components in our world
    @usableFromInline
    internal let count: Int
    
    /// Holds components for entities
    ///
    /// **Memory layout**:
    /// ```
    ///  |       entity 1       |        entity 2       |
    /// [ component1, component2, component1, component2 ]
    /// ```
    ///
    /// a component can be nil, if the entity does not have
    /// the specific component
    @usableFromInline
    internal var data: Arr<ComponentType?>
    
    /// The capacity of the component data array
    @usableFromInline
    internal var cap: Int {
        get { self.data.capacity }
    }
}

internal extension ComponentStore {
    @usableFromInline
    init() {
        self.count = ComponentType.count
        // self.data = Arr(repeating: nil, count: INITIAL_CAP)
        self.data = []
        self.data.reserveCapacity(Kiwi.arrayCap)
        
        #if DEBUG
        if Kiwi.printMemoryLayout {
            print("Component memory layout - size:", MemoryLayout<ComponentType>.size, "stride:", MemoryLayout<ComponentType>.stride, "alignment:", MemoryLayout<ComponentType>.alignment)
        }
        #endif
    }
}

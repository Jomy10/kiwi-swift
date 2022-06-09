/// Enums containing components should conform to this protocol
public protocol ComponentCollection {
    /// Returns the amount of cases of the enum
    @inlinable
    static var count: Int { get }
    
    /// Returns the id of component `c`
    ///
    /// Overriding the standard implementation will give a serious performance boost
    ///
    /// **Example implementation**
    /// ```swift
    /// extension Component: ComponentCollection {
    ///   // This is the amount of components in the enum
    ///   static let count: Int = 3
    ///   // This returns an id for each component.
    ///   // Only use ids from 0 to `count` - 1
    ///   static func id(_ c: Self) -> Int {
    ///     switch c {
    ///       case .Position: return Self.POSITION
    ///       case .Velocity: return Self.VELOCITY
    ///       case .Name:     return Self.NAME
    ///     }
    ///   }
    /// }
    ///
    /// extension Components {
    ///    static let POSITION = 0
    ///    static let VELOCITY = 1
    ///    static let NAME = 2
    /// }
    /// ```
    @inlinable
    static func id(_ c: Self) -> Int
    
    /// Only use this method when using the default implementation
    @inlinable
    static subscript(_ c: String) -> Int { get }
    
    /// Returs the id of this component
    @inlinable
    var id: Int { get }
}

public extension ComponentCollection {
    @inlinable
    var id: Int { return Self.id(self) }
    
    // Standard implementation that automatically assigns ids to enum cases
    // in the order they are called in
    @inlinable
    static func id(_ c: Self) -> Int {
        let (label, _) = Mirror(reflecting: c).children.first!
        return Self[label!]
    }
    
    @inlinable
    static subscript(_ c: String) -> Int {
        if let val = Kiwi.enumCases[c] {
            return val
        } else {
            Kiwi.enumCases[c] = Kiwi.caseCounter
            defer { Kiwi.caseCounter += 1 }
            return Kiwi.caseCounter
        }
    }
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

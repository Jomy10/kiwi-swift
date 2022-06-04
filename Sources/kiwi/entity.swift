/// An entity in the ecs
///
/// represents an entityID
public typealias Entity = Int

/// Holds all entity data
///
/// - I: the `FixedWidthInteger` type for the array that holds the enetity data.
///      the byte size of this integer should be enough to hold
///      the total amount of components in the world (1 bit per component)
/// - F: the integer type for the flag data of entities.
///      the byte size of this integer should be enough to hold
///      the total amount of flags you wish to inclide + 1 for
///      a flag used by the ecs system. (1 bit per flag + 1 bit)
@usableFromInline
internal struct EntityStore<I: FixedWidthInteger, F: FixedWidthInteger> {
    /// Amount of entityIDs
    ///
    /// Is increased whenever a new entityID is created
    /// i.e. when an entity is spawned and it isn't assignd
    /// an ID from a previous, dead entity
    @usableFromInline
    internal var count: Int

    /// Holds all entity data
    ///
    /// **Memory layout**:
    /// ```
    ///   ent1  ent2  ent3
    /// [ 0000, 0001, 0010 ]
    /// ```
    ///
    /// Each bit represents a component using its index.
    /// In the above eample, there are 4 components (and
    /// a max of 4 components)
    ///
    /// The index into the array represents the entity id
    @usableFromInline
    internal var mask: Arr<I>
    
    /// Capacity of the entity `mask` array.
    /// Is equivalent to the capacity of the `flag` array
    @usableFromInline
    internal var cap: Int {
        get { self.mask.capacity }
    }
    
    /// Flags for components
    ///
    /// Has the same memory layout as the `mask`
    @usableFromInline
    internal var flags: Arr<F>
}

internal extension EntityStore {
    @usableFromInline
    init() {
        self.count = 0
        self.mask = []
        self.mask.reserveCapacity(Kiwi.arrayCap)
        self.flags = []
        self.flags.reserveCapacity(Kiwi.arrayCap)
    }
}

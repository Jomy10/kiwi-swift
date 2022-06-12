extension World {
    /// Add a flag to the entity with the specified id
    ///
    /// - Do not set flags of id 0! These are used by the ecs to
    /// determine dead entities
    @inlinable
    public mutating func setFlag(entity: Entity, _ flag: FlagType) {
        self.entities.flags[entity] |= (1 << flag)
    }
    
    // TODO: rmFlag
    
    @inlinable
    public func readFlag(entity: Entity, _ flag: FlagType) -> Bool {
        self.entities.flags[entity] & (1 << flag) != 0
    }
    
    @inlinable
    public func queryFlags<Q: RandomAccessCollection>(_ query: Q) -> ContiguousArray<Entity> where Q.Element == FlagType {
        var _query: FlagType = 0
        for c in query {
            _query |= (1 << c)
        }
        
        var result: Arr<Int> = []
        for (i, fMask) in self.entities.flags.enumerated() {
            if fMask & _query == _query {
                result.append(i)
            }
        }
        
        return result
    }
    
    @inlinable

    public func readFlagsQuery<Q: RandomAccessCollection>(_ query: Q, _ cb: (Entity, UnsafePointerArraySlice<ComponentType?>) -> ()) where Q.Element == FlagType {
        self.readForEach(entities: queryFlags(query), cb)
    }
}

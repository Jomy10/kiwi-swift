extension World {
    /// Queries all entities that contain all of the given components and returns those entities
    @inlinable
    public func query<Q: RandomAccessCollection>(_ query: Q) -> ContiguousArray<Entity>  where Q.Element == Int {
        // Build the query
        // e.g. component ids 0 and 2: 0101
        var _query: EntityDataType = 0
        for c in query {
            _query |= (1 << c)
        }
        
        var result: Arr<Int> = []
        for (i, eMask) in self.entities.mask.enumerated() { // TODO: if not alive skip? Definitely needs to be present in the `not` queries
            // 0111  0101  0001
            // 0101  0101  0101
            // true  true  false
            if eMask & _query == _query {
                result.append(i)
            }
        }
        
        return result
    }
    
    /// Loop over all entities having all of the specified components
    @inlinable
    public func query<Q: RandomAccessCollection>(_ query: Q, _ cb: (Entity, UnsafePointerArraySlice<ComponentType?>) -> ()) where Q.Element == Int {
        self.readForEach(entities: self.query(query), cb)
    }
    
    /// Loop over all entities having all of the specified components. 
    /// Return true if you wantt to exit, otherwise return false
    @inlinable
    public func exitableQuery<Q: RandomAccessCollection>(_ query: Q, _ cb: (Entity, UnsafePointerArraySlice<ComponentType?>) -> Bool) where Q.Element == Int {
        var _query: EntityDataType = 0
        for c in query {
            _query |= (1 << c)
        }
        
        entityLoop: for (i, eMask) in self.entities.mask.enumerated() {
            if eMask & _query == _query {
                var br = false
                self.components.data.withUnsafeBufferPointer { buf in
                    br = cb(i, UnsafePointerArraySlice(buf, start: i * self.components.count))
                }
                if br { break entityLoop }
            }
        }
    }
    
    /// Queries all entities containing all of the given componens and none of the given `not` components
    @inlinable
    public func query<Q: RandomAccessCollection, N: RandomAccessCollection>(_ query: Q, not: N) -> ContiguousArray<Entity> where Q.Element == Int, N.Element == Int {
        var _query: EntityDataType = 0
        for c in query {
            _query |= (1 << c)
        }
        var _queryNot: EntityDataType = 0
        for c in not {
            _queryNot |= (1 << c)
        }
        
        var result: Arr<Int> = []
        for (i, eMask) in self.entities.mask.enumerated() {
            //  0100          0101
            // ~0001         ~0001
            //  0100 -> true  0100 -> false
            if eMask & _query == _query && eMask & ~_queryNot == eMask {
                result.append(i)
            }
        }
        
        return result
    }
    
    @inlinable
    public func query<Q: RandomAccessCollection, N: RandomAccessCollection>
        (_ query: Q, not: N, _ cb: (Entity, UnsafePointerArraySlice<ComponentType?>) -> ())
        where Q.Element == Int, N.Element == Int
    {
        self.readForEach(entities: self.query(query, not: not), cb)
    }
    
    /// Query all entities containing none of the given components
    @inlinable
    public func query<N: RandomAccessCollection>(not: N) -> ContiguousArray<Entity> where N.Element == Int {
        var _queryNot: EntityDataType = 0
        for c in not {
            _queryNot |= (1 << c)
        }
        
        var result: Arr<Int> = []
        for (i, eMask) in self.entities.mask.enumerated() {
            if eMask & ~_queryNot == eMask {
                result.append(i)
            }
        }
        
        return result
    }
    
    @inlinable
    public func query<N: RandomAccessCollection>(not: N, _ cb: (Entity, UnsafePointerArraySlice<ComponentType?>) -> ()) where N.Element == Int {
        self.readForEach(entities: self.query(not: not), cb)
    } 
}

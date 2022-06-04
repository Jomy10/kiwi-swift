/// A world holds all data of an ecs
public struct World<ComponentType: ComponentCollection, EntityDataType: FixedWidthInteger, FlagType: FixedWidthInteger> {
    @usableFromInline
    internal var components: ComponentStore<ComponentType>
    @usableFromInline
    internal var entities: EntityStore<EntityDataType, FlagType>
    /// Holds all dead entity ids that can be reused
    @usableFromInline
    internal var entityPool: Arr<Int>
}

extension World {
    public init() {
        self.components = ComponentStore()
        self.entities   = EntityStore()
        self.entityPool = []
    }
    
    /// Create a new entity and return its id
    @inlinable
    public mutating func createEntity() -> Entity {
        var id: Int
                
        if self.entityPool.count > 0 {
            // take an index from the pool of available enttity indexes
            id = self.entityPool.popLast().unsafelyUnwrapped // will always be some
        } else {
            id = self.entities.count
            self.entities.count += 1
            if self.entities.cap == id {
                // Double entitiy capacity
                self.entities.mask.reserveCapacity(self.entities.cap * 2)
                self.entities.flags.reserveCapacity(self.entities.cap * 2)
                self.components.data.reserveCapacity(self.components.cap * 2)
            }
        }
        
        if self.entities.mask.count == id {
            self.entities.mask.append(0)
            self.entities.flags.append(0)
            // Initialize components as nil
            self.components.data.append(contentsOf: Arr<ComponentType?>(repeating: nil, count: self.components.count))
        } else {
            self.entities.mask[id] = 0 // reset entity data
            self.entities.flags[id] = 0 // reset flag data
        }
        
        // components.data[entityId * self.components.count + component.id] = component

        self.entities.flags[id] |= 1 // (1 << 0); alive is the first flag (index 0)
        
        return id
    }
    
    /// Create a new entity with the given components
    @discardableResult
    public mutating func createEntity(with components: [ComponentType]) -> Entity {
        let id = self.createEntity()
        for comp in components {
            self.setComponent(entity: id, comp)
        }
        return id
    }
    
    /// Check if an entity is alive
    public mutating func isAlive(_ entityId: Entity) -> Bool {
        self.entities.flags[entityId] & 1 != 0
    }
    
    // ==================
    // Reading components
    // ==================
    
    /// Check if an entity has a component
    public func hasComponent(entity entityId: Entity, _ componentId: Int) -> Bool {
        self.entities.mask[entityId] & (1 << componentId) != 0
    }
    
    /// Read a component for an entity
    ///
    /// - Returns: none if the entity does not have the component, some otherwise
    public func read(entity entityId: Entity, component componentId: Int) -> ComponentType? {
        if self.hasComponent(entity: entityId, componentId) {
            return self.components.data[entityId * self.components.count + componentId]
        } else {
            return .none
        }
    }
    
    /// Read a component for an entity.
    ///
    /// - Safety:
    ///     - Unsafely unwraps the component for the entity, without checking wheter it has the component
    public func unsafeRead(entity entityId: Entity, component componentId: Int) -> ComponentType {
        self.components.data[entityId * self.components.count + componentId].unsafelyUnwrapped
    }
    
    /// Read an entity's components
    ///
    /// - Returns: the callback's return value
    private func read(entity eId: Entity, _ cb: (Entity, ArraySlice<ComponentType?>) -> Bool) -> Bool {
        let range: Range<Int> = eId * self.components.count..<eId * self.components.count + self.components.count
        let slice: ArraySlice<ComponentType?> = self.components.data[range]
        return cb(eId, slice)
    }
    
    /// Read an entity's components
    public func read(entity eId: Entity, _ cb: (Entity, ArraySlice<ComponentType?>) -> ()) {
        let range: Range<Int> = eId * self.components.count..<eId * self.components.count + self.components.count
        let slice: ArraySlice<ComponentType?> = self.components.data[range]
        cb(eId, slice)
    }
    
    /// Call a function with each entity and its `componentId` component
    ///
    /// - Safety:
    ///     - Unsafely unwraps the component, so make sure the component always is a valid component ID
    public func unsafeReadForEach<E: RandomAccessCollection>(entities: E, onComponent componentId: Int, _ cb: (Entity, ComponentType) -> ()) where E.Element == Entity {
        self.components.data.withUnsafeBufferPointer { buf in
            for eId in entities {
                cb(eId, buf[eId * self.components.count + componentId].unsafelyUnwrapped)
            }
        }
    }
    
    /// Call a function with each entity and its `componentId` component
    public func readForEach<E: RandomAccessCollection>(entities: E, onComponent componentId: Int, _ cb: (Entity, ComponentType?) -> ()) where E.Element == Entity{
        for eId in entities {
            cb(eId, self.components.data[eId * self.components.count + componentId])
        }
    }

    // TODO: wrap ArraySlice in a struct so user can call slice[0] instead of slice[slice.startIndex + 0]
    /// Call a function with each component of an entity
    public func readForEach<E: RandomAccessCollection>(entities: E, _ cb: (Entity, ArraySlice<ComponentType?>) -> ()) where E.Element == Entity {
        for eId in entities {
            cb(
                eId,
                self.components.data[
                    eId * self.components.count..<eId * self.components.count + self.components.count
                ]
            )
        }
    }

    /// Call a function with each component of an entity
    ///
    /// - Safety:
    ///     - As long as the `UnsafePointerArraySlice<ComponentType?>` is not used outside of the closure, using this function will not cause undefined behaviour
    public func unsafeReadForEach<E: RandomAccessCollection>(entities: E, _ cb: (Entity, UnsafePointerArraySlice<ComponentType?>) -> ()) where E.Element == Entity {
        self.components.data.withUnsafeBufferPointer { buf in
            for eId in entities {
                cb(
                    eId,
                    UnsafePointerArraySlice(buf, start: eId * self.components.count)
                )
            }
        }
    }
    
    /// Call a function with each component of an entity. Return true to exit the closure
    ///
    /// - Safety:
    ///     - As long as the `UnsafePointerArraySlice<ComponentType?>` is not used outside of the closure, using this function will not cause undefined behaviour
    public func unsafeExitableReadForEach<E: RandomAccessCollection>(entities: E, _ cb: (Entity, UnsafePointerArraySlice<ComponentType?>) -> Bool) where E.Element == Entity {
        self.components.data.withUnsafeBufferPointer { buf in
            for eId in entities {
                if cb(
                    eId,
                    UnsafePointerArraySlice(buf, start: eId * self.components.count)
                ) {
                    break
                }
            }
        }
    }
    
    // ==================
    // Editing components
    // ==================
    
    /// Add a component with `componentId` to `entity` in this world
    /// Can be used to replace the existing component with the corresponding id
    @inlinable
    public mutating func setComponent(entity entityId: Entity, _ component: ComponentType) {
        // add boolean to entity
        self.entities.mask[entityId] |= (1 << component.id)
        // add component
        self.components.data[entityId * self.components.count + component.id] = component
    }
    
    /// Remove a component from an entity
    @inlinable
    public mutating func rmComponent(entity entityId: Entity, _ componentId: Int) {
        self.entities.mask[entityId] &= ~(1 << componentId)
    }
    
    /// Edit an entity's components in a callback. Returns the boolean of the callback
    private mutating func edit(entity eId: Entity, _ cb: (Entity, inout ArraySlice<ComponentType?>) -> Bool) -> Bool {
        let range: Range<Int> = eId * self.components.count..<eId * self.components.count + self.components.count
        var slice: ArraySlice<ComponentType?> = self.components.data[range]
        let res = cb(eId, &slice)
        self.components.data.replaceSubrange(
            range,
            with: slice
        )
        return res
    }
    
    /// Edit an entity's components in a callback
    public mutating func edit(entity eId: Entity, _ cb: (inout ArraySlice<ComponentType?>) -> ()) {
        let range: Range<Int> = eId * self.components.count..<eId * self.components.count + self.components.count
        var slice: ArraySlice<ComponentType?> = self.components.data[range]
        cb(&slice)
        self.components.data.replaceSubrange(
            range,
            with: slice
        )
    }
    
    // TODO: wrap ArraySlice in a struct so user can call slice[0] instead of slice[slice.startIndex + 0]
    /// Edit all components of an entity using a callback
    public mutating func forEach<E: RandomAccessCollection>(entities: E, _ cb: (Entity, inout ArraySlice<ComponentType?>) -> ()) where E.Element == Entity {
        for eId in entities {
            let range: Range<Int> = eId * self.components.count..<eId * self.components.count + self.components.count
            var slice: ArraySlice<ComponentType?> = self.components.data[range]
            cb(eId, &slice)
            self.components.data.replaceSubrange(
                range,
                with: slice
            )
        }
    }

    /// Returns wheter the entity could be removed
    @discardableResult
    public mutating func rmEntity(_ entityId: Entity) -> Bool{
        if (self.entities.flags[entityId] & 1) != 0 { // flag alive = true
            self.entities.flags[entityId] &= ~1 // flag alive -> false
            self.entities.mask[entityId] = 0 // reset entity
            self.entityPool.append(entityId) // entityId available again
            return true
        } else {
            return false
        }
    }
    
    // =======
    // Queries
    // =======
    
    /// Queries all entities that contain all of the given components and returns those entities
    public func query<Q: RandomAccessCollection>(_ query: Q) -> ContiguousArray<Entity>  where Q.Element == Int {
        // Build the query
        // e.g. component ids 0 and 2: 0101
        var _query: EntityDataType = 0
        for c in query {
            _query |= (1 << c)
        }
        
        var result: Arr<Int> = []
        for (i, eMask) in self.entities.mask.enumerated() {
            // 0111  0101  0001
            // 0101  0101  0101
            // true  true  false
            if eMask & _query == _query {
                result.append(i)
            }
        }
        
        return result
    }
    
    /// Query all entities with the given components
    ///
    /// - Parameters:
    ///    - query: An array of components the entity should have
    //     - cd: a callback that is called with an array slice of an entity's components
    public mutating func query<Q: RandomAccessCollection>(_ query: Q, _ cb: (Entity, inout ArraySlice<ComponentType?>) -> ()) where Q.Element == Int {
        self.forEach(entities: self.query(query), cb)
    }
    
    /// Stops the query when the callback returns true
    public mutating func exitableQuery<Q: Sequence>(_ query: Q, _ cb: (Entity, inout ArraySlice<ComponentType?>) -> Bool) where Q.Element == Int {
        var _query: EntityDataType = 0
        for c in query {
            _query |= (1 << c)
        }
        
        for (i, eMask) in self.entities.mask.enumerated() {
            if eMask & _query == _query {
                if self.edit(entity: i, cb) { // Callback returned true
                    break
                }
            }
        }
    }
    
    /// A query that does not returnn an inout parameter to the closure
    public func readQuery<Q: RandomAccessCollection>(_ query: Q, _ cb: (Entity, ArraySlice<ComponentType?>) -> ()) where Q.Element == Int {
        self.readForEach(entities: self.query(query), cb)
    }
    
    public func unsafeReadQuery<Q: RandomAccessCollection>(_ query: Q, _ cb: (Entity, UnsafePointerArraySlice<ComponentType?>) -> ()) where Q.Element == Int {
        self.unsafeReadForEach(entities: self.query(query), cb)
    }
    
    /// Will read until the callback returns true
    public func exitableReadQuery<Q: RandomAccessCollection>(_ query: Q, _ cb: (Entity, ArraySlice<ComponentType?>) -> Bool) where Q.Element == Int {
        var _query: EntityDataType = 0
        for c in query {
            _query |= (1 << c)
        }
        
        for (i, eMask) in self.entities.mask.enumerated() {
            if eMask & _query == _query {
                if self.read(entity: i, cb) { // Callback returned true
                    break
                }
            }
        }
    }
    
    /// Queries all entities containing all of the given componens and none of the given `not` components
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
    
    public mutating func query<Q: RandomAccessCollection, N: RandomAccessCollection>(_ query: Q, not: N, _ cb: (Entity, inout ArraySlice<ComponentType?>) -> ()) where Q.Element == Int, N.Element == Int {
        self.forEach(entities: self.query(query, not: not), cb)
    }
    
    /// A query that does not returnn an inout parameter to the closure
    public func readQuery<Q: RandomAccessCollection, N: RandomAccessCollection>(_ query: Q, not: N, _ cb: (Entity, ArraySlice<ComponentType?>) -> ()) where Q.Element == Int, N.Element == Int {
        self.readForEach(entities: self.query(query, not: not), cb)
    }
    
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
    
    /// A query returning all the components of the selected entities mutably
    public mutating func query<N: RandomAccessCollection>(not: N, _ cb: (Entity, inout ArraySlice<ComponentType?>) -> ()) where N.Element == Int {
        self.forEach(entities: self.query(not: not), cb)
    }
    
    /// A query that does not returnn an inout parameter to the closure
    public func readQuery<N: RandomAccessCollection>(not: N, _ cb: (Entity, ArraySlice<ComponentType?>) -> ()) where N.Element == Int {
        self.readForEach(entities: self.query(not: not), cb)
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

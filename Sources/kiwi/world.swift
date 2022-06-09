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
    @inlinable
    public mutating func isAlive(_ entityId: Entity) -> Bool {
        self.entities.flags[entityId] & 1 != 0
    }
    
    // ==================
    // Reading components
    // ==================
    
    /// Check if an entity has a component
    @inlinable
    public func hasComponent(entity entityId: Entity, _ componentId: Int) -> Bool {
        self.entities.mask[entityId] & (1 << componentId) != 0
    }
    
    /// Read a component for an entity, checking if the entity has the specified component
    ///
    /// - Returns: none if the entity does not have the component, some otherwise
    @inlinable
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
    @inlinable
    public func unsafeRead(entity entityId: Entity, component componentId: Int) -> ComponentType {
        self.components.data[entityId * self.components.count + componentId].unsafelyUnwrapped
    }
    
    /// Read all components of an entity
    @inlinable
    public func readAll(entity eId: Entity, _ cb: (UnsafePointerArraySlice<ComponentType?>) -> ()) {
        self.components.data.withUnsafeBufferPointer { buf in
            cb(UnsafePointerArraySlice(buf, start: eId * self.components.count))
        }
    }
    
    /// Read all components of an entity
    @inlinable
    internal func readAll(entity eId: Entity, _ cb: (Entity, UnsafePointerArraySlice<ComponentType?>) -> Bool) -> Bool {
        self.components.data.withUnsafeBufferPointer { buf in
            return cb(eId, UnsafePointerArraySlice(buf, start: eId * self.components.count))
        }
    }
    
    /// Call a function with each entity and its `componentId` component
    ///
    /// - Safety:
    ///     - Unsafely unwraps the component, so make sure the component always is a valid component ID
    @inlinable
    public func readForEach<E: RandomAccessCollection>(entities: E, onComponent componentId: Int, _ cb: (Entity, ComponentType) -> ()) where E.Element == Entity {
        self.components.data.withUnsafeBufferPointer { buf in
            for eId in entities {
                cb(eId, buf[eId * self.components.count + componentId].unsafelyUnwrapped)
            }
        }
    }
    
    /// Call a function with each component of an entity
    ///
    /// - Safety:
    ///     - As long as the `UnsafePointerArraySlice<ComponentType?>` is not used outside of the closure, using this function will not cause undefined behaviour
    @inlinable
    public func readForEach<E: RandomAccessCollection>(entities: E, _ cb: (Entity, UnsafePointerArraySlice<ComponentType?>) -> ()) where E.Element == Entity {
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
    @inlinable
    public func exitableReadForEach<E: RandomAccessCollection>(entities: E, _ cb: (Entity, UnsafePointerArraySlice<ComponentType?>) -> Bool) where E.Element == Entity {
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
    
    /// Returns wheter the entity could be removed
    @inlinable
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
    
    /// Remove an entity, without cheking if it is alive.
    /// Doing this on a dead entity can have some negative side-effects
    @inlinable
    public mutating func uncheckedRmEntity(_ entityId: Entity) {
        self.entities.flags[entityId] &= ~1 // flag alive -> false
        self.entities.mask[entityId] = 0 // reset entity
        self.entityPool.append(entityId) // entityId available again
    }
}

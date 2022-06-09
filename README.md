<p align="center">
  <img src="logo.png" alt="kiwi ecs">
</p>

<p align="center">
  A performant, zero-dependency ECS library written in pure swift.
</p>

## Usage

```swift
.package(url: "https://github.com/Jomy10/kiwi", .branch("master"))
```

**NOTE**: This library is still very new, and I'm working on getting the api to be nicer 
to work with.

### Components

*This is currently my least favorite syntax in the ecs library, and I am looking for ways
to make this less cumbersome to write*

Components are modelled as an enum. 

```swift
enum Component {
  case Position(x: Float32, y: Float32)
  case Velocity(x: Float32, y: Float32)
  case Name(String)
}
```

This enum should implement the `ComponentCollection` protocol:

```swift
extension Component: ComponentCollection {
  // This is the amount of components in the enum
  static let count: Int = 3
  // This returns an id for each component.
  // Only use ids from 0 to `count` - 1
  static func id(_ c: Self) -> Int {
    switch c {
      case .Position: return 0
      case .Velocity: return 1
      case .Name:     return 2
    }
  }
}
```

For convenience, you can add static constants to your component enum.
I will be referring to these constants in the code examples below a lot
```swift
extension Component {
  static let POSITION = 0
}

extension Component: ComponentCollection {
  static let count: Int = 1
  static func id(_ c: Self) -> Int {
    switch c {
      case .Position: return Position
    }
  }
}
```

**NOTE**: There is a default implementation for `id(_ c: Self)`. However,
this default implementation is much slower compared to adding the switch statement
manually (uot-bench runs at an average of 7ms using manual implementation, and runs
at 17ms using default implementation). 

If you want to use the default implementation, you can do: `Component["Position"]`
instead of `Component.POSITION`.

I would advice setting up **Sourcery** for this (detailed explanation coming later).

### World

A world holds all entities and components. You can create a new world like this:

```swift
var world: World<Component, Int8, Int8> = World()
                 ^^^^^^^^^  ^^^^  ^^^^
                    (1)     (2)   (3)
```

1. This type is the component enum you created earlier
2. This is the type for the entity mask. All you need to worry about is that this type
needs to be large enough for the number of components, so an `Int8` can hold 8 components,
an `Int16` can hold 16 componnts, etc.
3. This is the type for entity flags. This feature currently does not have an outside API,
so set this to an `Int8`

### Entities

An entity is just a number. 

To create a new entity, use the `createEntity` method on your `World`.

```swift
let id = world.createEntity()
```

#### Adding components to an entity

```swift
// Add a new component to an entity after creation
let id = world.createEntity()
world.setComponent(entity: id, .Position(x: 0, y: 1))
world.setComponent(entity: id, .Name("Jim Root"))

// Add a component while creating the entity
let id = world.createEntity(with: [
  .Position(x: 0, y: 1),
  .Name("Jim Root")
])
```

#### Removing components

```swift
world.rmComponent(entity: id, Component.POSITION)
                              ^^^^^^^^^^^^^^^^^^
                         This is a component id (position)
// Is equivalent to:
world.rmComponent(entity: id, 0)


world.hasComponent(entity: id, Component.POSITION) // false
```

In the above example, you can see why it is handy to declare the static constants in your
`Component` enum.

#### Removing entities

```swift
world.isAlive(id) // true
world.rmEntity(id)
world.isAlive(id) // false
```

#### Reading and editing components for a single entity

```swift
let positionComponent = world.read(entity: id, component: Component.POSITION)!
``` 

```swift
world.edit(entity: id) { components in
  components[components.startIndex + Component.POSITION] = .Position(x: 5, y: 6)
}
```

*We use `components.startIndex` here because the edit method returns an ArraySlice to the
closure. This might change in the future*


#### Reading and editing components for multiple entities

If you want to edit components for all entities containing a secific component(s), go to
the [Queries](#queries) chapter.

```swift
// Read
world.readForEach(entities: [0, 1, 3]) { (entityId, components) in
  let positionComponent = components[components.startIndex + Component.POSITION]
}

world.readForEach(entities: [0, 1, 3], onComponent: Component.POSITION) { (entityId, positionComponent) in 

}

world.unsafeReadForEach(entities: [0, 1, 3]) { (entityId, components)
  // it is safe to use `positionComponent` outside of this closure, but not `components`!
  let positionComponent = components.get(Component.POSITION)
}

// Edit
world.forEach(entities: [0, 1, 3]) { (entityId, components) in
  components[components.startIndex + Component.POSITION] = .Position(x: 5, y: 6)
}
```

### Queries

```swift
// Query all entities with a position AND velocity
let entityIds = world.query([Components.POSITION, Components.VELOCITY])
// Query all entities with a position (more performant to use CollectionOfOne)
let entityIds = world.query(CollectionOfOne(Components.POSITION))
// These `entityIds` can be used in the aforementioned methods, or:

// mutable query
world.query([Components.POSITION, Components.VELOCITY]) { (entityId, components) in
  components[components.startIndex + Components.POSITION]
}
// Read query
world.readQuery([Components.POSITION, Components.VELOCITY]) { (entityId, components) in 
  let position = components[components.startIndex + Components.POSITION]
}
// Unsafe read query (unsafe because the components param can't be used outside the closure!)
world.unsafeReadQuery([Components.POSITION, Components.VELOCITY]) { (entityId, components) in
  let position = components.get(Components.POSITION)
}
// A read query that can be exited early
world.exitableReadQuery([Components.POSITION, Components.VELOCITY]) { (entityId, components) in
  let position = components[components.startIndex + Components.POSITION]
  if position.x == 0 {
    return true // exit query
  } else {
    return false // continue to the next query result
  }
}
```

With `not`

```swift
// Query all entities with a position components, but not a velocity and name components
world.query([Components.POSITION], not: [Components.VELOCITY, Components.NAME]) { (entityId, components) in 
  /*...*/
}

// Query all entities without a name component
world.query(not: CollectionOfOne(Components.NAME)) { (entityId, components) in
  /*...*/
}

// Also available as `world.query(not: ...)` and `world.readQuery(not: ..., _: cb)`
```

## Memory & performance considerations

In this section, I will discuss some more advanced concepts. So feel free to skip this.
This will definitely not be a necessary read for small game projects.

The size of your biggest components will affect the size of all others. To see the memory
size of your component enum (when running a DEBUG build), use `Kiwi.printMemoryLayout = true`.
The important parameter is the stride. For more information, see [Size, Stride, Alignment by swift unboxed](https://swiftunboxed.com/internals/size-stride-alignment/).

Setting the second (and third) type parameter of your World to an integer with less bits
will increase performance.

For more on performance, see [Sources/benches/performance-benches](Sources/benches/performance-benches).
You can run them with:
```sh
./bench.sh [benchmark]
```

See [bench.sh](bench.sh) for possible `benchmark` values (e.g. `mutQuery`)

## Note on looping

Doing a query inside of another query callback is very slow. The best solution I have right
now can be found in [Source/benches/uot-bench/main.swift](https://github.com/jomy10/kiwi/blob/master/Sources/benches/uot-bench/main.swift#L101-L109), 
line 101-109 shows collecting a query before using it inside of a loop (antoher query).

Also, see above chapter about performance. There is a `mutQuery` benchmark that might be
of interest.

## Stability and semver

This library is still in early development and has not been tested extensively (feel free to open an issue).
The api will change in upcoming versions. Old syntax will de deprecated first and will most likely be removed in
the next minor version. Patches will never contain breaking changes.

From 1.0 onwards, the api should be stable and breaking changes will only happen between major versions.

## License

This library is released under the [GNU LGPLv3](LICENSE) license.

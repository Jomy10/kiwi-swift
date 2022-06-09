import Benchmark
import Foundation
import kiwi

fileprivate enum Component {
    case Position(_ x: Int32, _ y: Int32)
    case Velocity(_ x: Int32, _ y: Int32)
}

extension Component: ComponentCollection {
    static var count = 2
    static func id(_ s: Self) -> Int {
        switch s {
            case .Position: return Self.POSITION
            case .Velocity: return Self.VELOCITY
        }
    }
    static let POSITION = 0
    static let VELOCITY = 1
}

/// Test different ways of querying entities and editing their components
internal func mutQueryBench() -> BenchmarkSuite {
    var baseWorld: World<Component, Int8, Int8> = World()
    for _ in 0..<1000 {
        baseWorld.createEntity(with: [.Position(0, 0), .Velocity(0, 0)])
    }

    let mutQuery = BenchmarkSuite(name: "Mutable Query Benches", settings: Iterations(10000), WarmupIterations(1000)) { suite in
        var world1 = baseWorld
        suite.benchmark("query") {
            world1.query(CollectionOfOne(Component.POSITION)) { (id, components) in
                guard case .Position(var x, var y) = components[components.startIndex + Component.POSITION] else { fatalError() }
                
                
                components[components.startIndex] = .Position(x, y)
            }
        }
    
        var world2 = baseWorld
        suite.benchmark("readQuery") {
            world2.readQuery(CollectionOfOne(Component.POSITION)) { (id, components) in
                guard case .Position(var x, var y) = components[components.startIndex + Component.POSITION] else { fatalError() }
            
                x += 1
                y += 1
            
                world2.setComponent(entity: id, .Position(x, y))
            }
        }
    
        var world3 = baseWorld
        suite.benchmark("unsafeReadQuery") {
            world3.unsafeReadQuery(CollectionOfOne(Component.POSITION)) { (id, components) in
                guard case .Position(var x, var y) = components.get(Component.POSITION) else { fatalError() }
            
                x += 1
                y += 1
            
                world3.setComponent(entity: id, .Position(x, y))
            }
        }
        
    
        var world4 = baseWorld
        suite.benchmark("query without callback") {
            let ids = world4.query(CollectionOfOne(Component.POSITION))
            for id in ids {
                guard case .Position(var x, var y) = world4.read(entity: id, component: Component.POSITION) else { fatalError() }
            
                x += 1
                y += 1
            
                world4.setComponent(entity: id, .Position(x, y))
            }
        }
    
        var world7 = baseWorld
        suite.benchmark("unsafe query without callback") {
            let ids = world7.query(CollectionOfOne(Component.POSITION))
            for id in ids {
                guard case .Position(var x, var y) = world7.unsafeRead(entity: id, component: Component.POSITION) else { fatalError() }
            
                x += 1
                y += 1
            
                world7.setComponent(entity: id, .Position(x, y))
            }
        }

        var world5 = baseWorld
        suite.benchmark("query + readForEach manual") {
            let ids = world5.query(CollectionOfOne(Component.POSITION))
            world5.readForEach(entities: ids) { (id, components) in
                guard case .Position(var x, var y) = components[components.startIndex + Component.POSITION] else { fatalError() }
            
                x += 1
                y += 1
            
                world5.setComponent(entity: id, .Position(x, y))
            }
        }

        var world6 = baseWorld
        suite.benchmark("query + unsafeReadForEacht") {
            let ids = world6.query(CollectionOfOne(Component.POSITION))
            world6.unsafeReadForEach(entities: ids) { (id, component) in
                guard case .Position(var x, var y) = component.get(0) else { fatalError() }
                
                x += 1
                y += 1
                
                world6.setComponent(entity: id, .Position(x, y))
            }
        }
    }
    return mutQuery
}

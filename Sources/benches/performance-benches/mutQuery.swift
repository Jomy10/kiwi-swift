import Benchmark
import Foundation
import kiwi

fileprivate enum Component {
    case Position(_ x: Int32, _ y: Int32)
}

extension Component: ComponentCollection {
    static var count = 1
    static func id(_ s: Self) -> Int {
        switch s {
            case .Position: return Self.POSITION
        }
    }
    static let POSITION = 0
}

/// Test different ways of querying entities and editing their components
internal func mutQueryBench() -> BenchmarkSuite {
    var baseWorld: World<Component, Int8, Int8> = World()
    for _ in 0..<1000 {
        baseWorld.createEntity(with: [.Position(0, 0)])
    }

    let mutQuery = BenchmarkSuite(name: "Mutable Query Benches", settings: Iterations(10000), WarmupIterations(1000)) { suite in
        var world1 = baseWorld
        suite.benchmark("query") {
            world1.query(CollectionOfOne(Component.POSITION)) { (id, components) in
                guard case .Position(var x, var y) = components[Component.POSITION] else { fatalError() }
            
                x += 1
                y += 1
            
                world1.setComponent(entity: id, .Position(x, y))
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
        suite.benchmark("query + readForEach") {
            let ids = world5.query(CollectionOfOne(Component.POSITION))
            world5.readForEach(entities: ids) { (id, components) in
                guard case .Position(var x, var y) = components[Component.POSITION] else { fatalError() }
            
                x += 1
                y += 1
            
                world5.setComponent(entity: id, .Position(x, y))
            }
        }

        var world6 = baseWorld
        suite.benchmark("query + exitableReadForEach") {
            let ids = world6.query(CollectionOfOne(Component.POSITION))
            world5.exitableReadForEach(entities: ids) { (id, components) in
                guard case .Position(var x, var y) = components[Component.POSITION] else { fatalError() }
            
                x += 1
                y += 1
            
                world6.setComponent(entity: id, .Position(x, y))
                return false
            }
        }
        
        var world8 = baseWorld
        suite.benchmark("query + readForEach onComponent") {
            let ids = world7.query(CollectionOfOne(Component.POSITION))
            world8.readForEach(entities: ids, onComponent: Component.POSITION) { (id, component) in
                guard case .Position(var x, var y) = component else { fatalError() }
            
                x += 1
                y += 1
            
                world8.setComponent(entity: id, .Position(x, y))
            }
        }
    }
    return mutQuery
}

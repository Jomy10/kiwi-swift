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

    // Return an object
    // Should communicate with original array
    // object[Component.POSITION] -> get/set component
    // 
    // (Version 0.2.0)
    // name                                                        time          std        iterations warmup
    // ----------------------------------------------------------------------------------------------------------------
    // Mutable Query Benches.query                                 191963.500 ns ±  15.96 %      10000 219421505.000 ns
    // Mutable Query Benches.readQuery                              26088.500 ns ±  29.92 %      10000  33585347.000 ns
    // Mutable Query Benches.unsafeReadQuery                        14715.000 ns ±  29.92 %      10000  14744950.000 ns
    // Mutable Query Benches.query without callback                367696.500 ns ±  12.30 %      10000 374945303.000 ns
    // Mutable Query Benches.query + readForEach manual             27780.000 ns ±  20.79 %      10000  32985300.000 ns
    // Mutable Query Benches.query + unsafeReadForEach onComponent  16051.500 ns ±  46.92 %      10000  16415956.000 ns
    //    
    // (Version 0.1.0)
    // name                                         time           std        iterations warmup
    // ---------------------------------------------------------------------------------------------------
    // Mutable Query Benches.query                  1532400.500 ns ±  26.65 %      10000 1641206012.000 ns
    // Mutable Query Benches.readQuery               894849.000 ns ±  27.44 %      10000  988560577.000 ns
    // Mutable Query Benches.unsafeReadQuery         883700.500 ns ±  28.89 %      10000  972118182.000 ns
    // Mutable Query Benches.query without callback 1005274.000 ns ±  26.93 %      10000 1099301777.000 ns
    let mutQuery = BenchmarkSuite(name: "Mutable Query Benches", settings: Iterations(10000), WarmupIterations(1000)) { suite in
        var world1 = baseWorld
        suite.benchmark("query") {
            world1.query(CollectionOfOne(Component.POSITION)) { (id, components) in
                guard case .Position(var x, var y) = components[components.startIndex + Component.POSITION] else { fatalError() }
            
                x += 1
                y += 1
            
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

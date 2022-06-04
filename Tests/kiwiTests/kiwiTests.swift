import XCTest
import Foundation
@testable import kiwi


typealias Arr = ContiguousArray

enum Component: Equatable {
    case Position(_ x: Int32, _ y: Int32)
    case Name(String)
}

extension Component: ComponentCollection {
    static let count: Int = 2
    static func id(_ c: Self) -> Int {
        switch c {
            case .Position: return 0
            case .Name: return 1
        }
    }
}

let INITIAL_CAP = Kiwi.arrayCap

final class kiwiTests: XCTestCase {    
    func testEntityCreation() {
        var world: World<Component, Int32, Int8> = World()
        let _ = world.createEntity()
        let _ = world.createEntity()
        
        XCTAssertEqual(world.getEntities().mask, [0, 0])
    }
    
    func testAddComponent() {
        var world: World<Component, Int8, Int8> = World()
        let e1 = world.createEntity()
        let e2 = world.createEntity()
        
        world.setComponent(entity: e2, .Position(0, 0))
        world.setComponent(entity: e1, .Position(10, 5))
        world.setComponent(entity: e2, .Name("Hello world"))
        
        let expected: ContiguousArray<Component?> = [
            .some(.Position(10, 5)),
            nil,
            .some(.Position(0, 0)),
            .some(.Name("Hello world")),
        ]
        
        XCTAssertEqual(world.getComponents().data, expected)
        
        let expectedMask: ContiguousArray<Int8> = [
            0b00000001,
            0b00000011,
        ]
        
        XCTAssertEqual(world.getEntities().mask, expectedMask)
    }
    
    func testRmComponent() {
        var world: World<Component, Int8, Int8> = World()
        let e1 = world.createEntity()
        let e2 = world.createEntity()
        
        world.setComponent(entity: e2, .Position(0, 0))
        world.setComponent(entity: e1, .Position(10, 5))
        world.setComponent(entity: e2, .Name("Hello world"))
        
        world.rmComponent(entity: e1, 0)
        world.rmComponent(entity: e1, 1)
        world.rmComponent(entity: e2, 1)
        
        let expectedMask: ContiguousArray<Int8> = [
            0b00000000,
            0b00000001,
        ]
        
        XCTAssertEqual(world.getEntities().mask, expectedMask)
    }
    
    func testHasComponent() {
        var world: World<Component, Int8, Int8> = World()
        let e1 = world.createEntity()
        let e2 = world.createEntity()
        
        world.setComponent(entity: e2, .Position(0, 0))
        world.setComponent(entity: e1, .Position(10, 5))
        world.setComponent(entity: e2, .Name("Hello world"))
        
        XCTAssertEqual(world.hasComponent(entity: e1, 0), true)
        XCTAssertEqual(world.hasComponent(entity: e1, 1), false)
        XCTAssertEqual(world.hasComponent(entity: e2, 0), true)
        XCTAssertEqual(world.hasComponent(entity: e2, 1), true)
        
        world.rmComponent(entity: e1, 0)
        world.rmComponent(entity: e1, 1)
        world.rmComponent(entity: e2, 1)
        
        XCTAssertEqual(world.hasComponent(entity: e1, 0), false)
        XCTAssertEqual(world.hasComponent(entity: e1, 1), false)
        XCTAssertEqual(world.hasComponent(entity: e2, 0), true)
        XCTAssertEqual(world.hasComponent(entity: e2, 1), false)
    }
    
    func testRmEntity() {
        var world: World<Component, Int8, Int8> = World()
        let e1 = world.createEntity()
        let e2 = world.createEntity()
        
        world.setComponent(entity: e2, .Position(0, 0))
        world.setComponent(entity: e1, .Position(10, 5))
        world.setComponent(entity: e2, .Name("Hello world"))
        
        XCTAssert(world.rmEntity(e1))
        
        XCTAssert(!world.isAlive(e1))
        
        let expectedMask: ContiguousArray<Int8> = [
            0b00000000,
            0b00000011,
        ]
        
        XCTAssertEqual(world.getEntities().mask, expectedMask)
        
        XCTAssertEqual(world.getEntityPool(), [0])
    }
    
    func testReadComponent() {
        var world: World<Component, Int8, Int8> = World()
        let e1 = world.createEntity()
        
        world.setComponent(entity: e1, .Position(0, 0))
        
        XCTAssertEqual(world.read(entity: e1, component: 0)!, .Position(0, 0))
    }
    
    func testQueryComponents() {
        var world: World<Component, Int8, Int8> = World()
        let e1 = world.createEntity()
        let e2 = world.createEntity()
        
        world.setComponent(entity: e2, .Position(0, 0))
        world.setComponent(entity: e1, .Position(10, 5))
        world.setComponent(entity: e2, .Name("Hello world"))
        
        let result1 = world.query(CollectionOfOne(1))
        let result2 = world.query([0, 1])
        let result3 = world.query(CollectionOfOne(0))
        
        let expected1: Arr<Int> = [e2]
        let expected2: Arr<Int> = [e2]
        let expected3: Arr<Int> = [e1, e2]
        
        XCTAssertEqual(result1, expected1)
        XCTAssertEqual(result2, expected2)
        XCTAssertEqual(result3, expected3)
    }
    
    func testQueryComponentsWithNot() {
        var world: World<Component, Int8, Int8> = World()
        let e1 = world.createEntity()
        let e2 = world.createEntity()
        let e3 = world.createEntity()
        let e4 = world.createEntity()
        
        world.setComponent(entity: e2, .Position(0, 0))
        world.setComponent(entity: e1, .Position(10, 5))
        world.setComponent(entity: e2, .Name("Hello world"))
        world.setComponent(entity: e3, .Name("Hello component 3"))
        world.setComponent(entity: e4, .Position(0, 1))
        
        let result = world.query(CollectionOfOne(0), not: CollectionOfOne(1))
        let expected: Arr<Int> = [e1, e4]
        
        XCTAssertEqual(expected, result)
    }
    
    func testQueryComponentNot() {
        var world: World<Component, Int8, Int8> = World()
        let e1 = world.createEntity()
        let e2 = world.createEntity()
        let e3 = world.createEntity()
        
        world.setComponent(entity: e2, .Position(0, 0))
        world.setComponent(entity: e1, .Position(10, 5))
        world.setComponent(entity: e2, .Name("Hello world"))
        world.setComponent(entity: e3, .Name("Hello component 3"))
        
        let result = world.query(not: CollectionOfOne(1))
        let expected: Arr<Int> = [e1]
        
        XCTAssertEqual(expected, result)
    }
        
    func testChangeEntityComponents() {
        var world: World<Component, Int8, Int8> = World()
        let e1 = world.createEntity()
        let e2 = world.createEntity()
        
        world.setComponent(entity: e2, .Position(0, 0))
        world.setComponent(entity: e1, .Position(10, 5))
        world.setComponent(entity: e2, .Name("Hello world"))
        
        world.forEach(entities: [e1]) { (_, comps) in
            if case .Position(var x, var y) = comps[comps.startIndex+0] {
                x = 2
                y = 2
                comps[comps.startIndex + 0] = .Position(x, y)
            } else {
                exit(1)
            }
        }
        
        let expected: ContiguousArray<Component?> = [
            .some(.Position(2, 2)),
            nil,
            .some(.Position(0, 0)),
            .some(.Name("Hello world")),
        ]
        
        XCTAssertEqual(world.getComponents().data, expected)
    }
    
    func testQueryMut() {
        var world: World<Component, Int8, Int8> = World()
        let e1 = world.createEntity()
        let e2 = world.createEntity()
        let e3 = world.createEntity()
        
        world.setComponent(entity: e2, .Position(0, 0))
        world.setComponent(entity: e1, .Position(10, 5))
        world.setComponent(entity: e2, .Name("Hello world"))
        world.setComponent(entity: e3, .Name("Hello component 3"))
        
        world.query(CollectionOfOne(0)) { (_, slice) in
            if case .Position(var x, var y) = slice[slice.startIndex + 0] {
                x = 2
                y = 2
                slice[slice.startIndex + 0] = .Position(x, y)
            } else {
                exit(1)
            }
        }
        
        let expected: ContiguousArray<Component?> = [
            .some(.Position(2, 2)),
            .none,
            .some(.Position(2, 2)),
            .some(.Name("Hello world")),
            .none,
            .some(.Name("Hello component 3"))
        ]
        
        XCTAssertEqual(world.getComponents().data, expected)
    }
}    

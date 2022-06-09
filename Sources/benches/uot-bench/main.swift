//=============================================================//
// Benchmark based on UnitOfTime's Go vs Bevy benchmark        //
// https://github.com/unitoftime/ecs/blob/master/bench/main.go //
//=============================================================//

import Foundation
import kiwi

typealias Arr = ContiguousArray

struct Vec2 {
    var x: Float64
    var y: Float64
}

extension Vec2 {
    init(_ x: Float64, _ y: Float64) {
        self.x = x
        self.y = y
    }
}

enum Component {
    case Position(Vec2)
    case Velocity(Vec2)
    case Collider(radius: Float64, count: Int32)
}

extension Component: ComponentCollection {
    static let count: Int = 3
    @inlinable
    static func id(_ c: Self) -> Int {
        switch c {
            case .Position: return Self.POSITION
            case .Velocity: return Self.VELOCITY
            case .Collider: return Self.COLLIDER
        }
    }
}

print("size:", MemoryLayout<Component>.size, "stride:", MemoryLayout<Component>.stride, "alignment:", MemoryLayout<Component>.alignment)

extension Component {
    static let POSITION = 0
    static let VELOCITY = 1
    static let COLLIDER = 2
}

func main() {
    let SIZE = 10000
    let COLLISION_LIMIT: Int32 = 0
    let ITERATIONS = 1000
    
    let MAX_SPEED = 10.0
    let MAX_POS = 100.0
    let MAX_COLLIDER = 1.0
    
    var world: World<Component, Int8, Int8> = World()
    
    for _ in 0..<SIZE {
        world.createEntity(with: [
            .Position(Vec2(MAX_POS * Float64.random(in: 0.0..<1.0), MAX_POS * Float64.random(in: 0.0..<1.0))),
            .Velocity(Vec2(MAX_SPEED * Float64.random(in: 0.0..<1.0), MAX_SPEED * Float64.random(in: 0.0..<1.0))),
            .Collider(
                radius: MAX_COLLIDER * Float64.random(in: 0.0..<1.0),
                count: 0
            )
        ])
    }
    
    var loopCounter = 0
    let fixedTime = 0.015
    
    var start = Date()
    var dt = start.timeIntervalSinceNow
    
    for iterCount in 0..<ITERATIONS {
        start = Date()
        
        // move circles
        world.unsafeReadQuery([Component.POSITION, Component.VELOCITY]) { (id, comps) in
            guard case .Position(var pos) = comps.get(Component.POSITION) else { fatalError() }
            guard case .Velocity(var vel) = comps.get(Component.VELOCITY) else { fatalError() }
            
            pos.x += vel.y * fixedTime
            pos.y += vel.y * fixedTime
            
            // update positions
            if pos.x <= 0 || pos.x >= MAX_POS {
                vel.x = -vel.x
            }
            if pos.y <= 0 || pos.y >= MAX_POS {
                vel.y = -vel.y
            }
            
            loopCounter += 1
            
            world.setComponent(entity: id, .Position(pos))
            world.setComponent(entity: id, .Velocity(vel))
        }
        
        // Check collisions
        var deathCount = 0
        let innerQueryIds = world.query([Component.POSITION, Component.COLLIDER])
        var targetPositions: Arr<Component> = []
        var targetColliders: Arr<Component> = []
        
        for target in innerQueryIds {
            targetPositions.append(world.unsafeRead(entity: target, component: Component.POSITION))
            targetColliders.append(world.unsafeRead(entity: target, component: Component.COLLIDER))
        }

        world.unsafeReadQuery([Component.POSITION, Component.COLLIDER]) { (id, comps) in
            guard case .Position(let pos) = comps.get(Component.POSITION) else { fatalError() }
            guard case .Collider(let colRadius, var colCount) = comps.get(Component.COLLIDER) else { fatalError() }
            
            // world.unsafeReadForEach(entities: innerQueryIds) { (targetId, targetComps) in
            for (idx, targetId) in innerQueryIds.enumerated() {
                if targetId == id { break }
                
                // guard case .Position(let targPos) = comps.get(Component.POSITION) else { fatalError() }
                // guard case .Collider(let targColRadius, _) = comps.get(Component.COLLIDER) else { fatalError() }
                
                guard case .Position(let targPos) = targetPositions[idx] else { fatalError("Found unexpected enum type for target position") }
                guard case .Collider(let targColRadius, _) = targetColliders[idx] else { fatalError("Found unexpected enum type for target collider") }

                let dx = pos.x - targPos.x
                let dy = pos.y - targPos.y
                let distSq = (dx * dx) + (dy * dy)
                
                let dr = colRadius + targColRadius
                let drSq = dr * dr
                
                if drSq > distSq {
                    colCount += 1
                }
                
                if COLLISION_LIMIT > 0 && colCount > COLLISION_LIMIT {
                    deathCount += 1
                }
                
                world.setComponent(entity: id, .Collider(radius: colRadius, count: colCount))
                
                loopCounter += 1
            }
        }
        
        dt = start.timeIntervalSinceNow
        print(iterCount, dt * -1000, loopCounter)
        loopCounter = 0
    } // end iterations
    
    world.unsafeReadQuery([Component.COLLIDER]) { (id, comps) in
        guard case .Collider(_, let count) = comps.get(Component.COLLIDER) else { fatalError() }
        print(id, count)
    }
}

main()

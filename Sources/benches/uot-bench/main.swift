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

// TODO: find a better solution than his
extension Component {
    static let POSITION = 0
    static let VELOCITY = 1
    static let COLLIDER = 2
}

@inline(__always)
func main() {
    let SIZE = 1000
    let COLLISION_LIMIT = 0 // 0 or 100
    
    let ITERATIONS = 1000
    
    let MAX_SPEED: Float64 = 10.0
    let MAX_POS: Float64 = 100.0
    let MAX_COLLIDER: Float64 = 1.0
    
    var world: World<Component, Int8, Int8> = World()

    for _ in 0..<SIZE {
        let ent = world.createEntity()
        world.setComponent(entity: ent, .Position(Vec2(MAX_POS * Float64.random(in: 0.0..<1.0), MAX_POS * Float64.random(in: 0.0..<1.0))))
        world.setComponent(entity: ent, .Velocity(Vec2(MAX_SPEED * Float64.random(in: 0.0..<1.0), MAX_SPEED * Float64.random(in: 0.0..<1.0))))
        world.setComponent(entity: ent, .Collider(
            radius: MAX_COLLIDER * Float64.random(in: 0.0..<1.0),
            count: 0
        ))
    }
    
    var start = Date()
    var dt = start.timeIntervalSinceNow
    let fixedTime = 0.015
    for _ in 0..<ITERATIONS {
        start = Date()
        
        // update positions
        world.query([Component.POSITION, Component.VELOCITY]) { (_, comps) in
            
            guard case .Velocity(var vel) = comps[comps.startIndex + Component.VELOCITY] else { fatalError("Found unexpected enum type for velocity") }
            guard case .Position(var pos) = comps[comps.startIndex] else { fatalError("Found unexpected enum type for position") }
            
            pos.x += vel.x * fixedTime
            pos.y += vel.y * fixedTime
            
            // Bump into the bounding rect
            if pos.x <= 0 || pos.x >= MAX_POS {
                vel.x = -vel.x
            }
            if pos.y <= 0 || pos.y >= MAX_POS {
                vel.y = -vel.y
            }
            
            comps[comps.startIndex + Component.VELOCITY] = .Velocity(vel)
            comps[comps.startIndex] = .Position(pos)
        }
        
        // Check collisions, increent the count if a collision happens
        var deathCount = 0
        var targets = world.query([Component.POSITION, Component.COLLIDER])
        var targetPositions: Arr<Component> = []
        var targetColliders: Arr<Component> = []
        
        for target in targets {
            targetPositions.append(world.unsafeRead(entity: target, component: Component.POSITION))
            targetColliders.append(world.unsafeRead(entity: target, component: Component.COLLIDER))
        }
        
        // POINTER VERSION
        world.unsafeReadQuery([Component.POSITION, Component.COLLIDER]) { (entity, components) in
            guard case .Position(let pos) = components.get(Component.POSITION) else { fatalError("Found unexpected enum type for target position") }
            guard case .Collider(radius: let rad, count: var colliderCount) = components.get(Component.COLLIDER) else { fatalError("Found unexpected enum type for target collider") }
        /* ARRAY SLICE VERSION
        world.readQuery([Component.POSITION, Component.COLLIDER]) { (entity, components) in
            guard case .Position(let pos) = components[components.startIndex] else { fatalError("Found unexpected enum type for target position") }
            guard case .Collider(radius: let rad, count: var colliderCount) = components[components.startIndex + Component.COLLIDER] else { fatalError("Found unexpected enum type for target collider") }
         */
            
            for (idx, target) in targets.enumerated() {
                if target == entity { continue }

                guard case .Position(let targPos) = targetPositions[idx] /*world.unsafeReadComponent(entity: target, Component.POSITION)*/ else { fatalError("Found unexpected enum type for target position") }
                guard case .Collider(radius: let targRad, count: _) = targetColliders[idx] /*world.unsafeReadComponent(entity: target, Component.COLLIDER)*/ else { fatalError("Found unexpected enum type for target collider") }
                
                let dx = pos.x - targPos.x
                let dy = pos.y - targPos.y
                let distSq = (dx * dx) + (dy * dy)
                
                let dr = rad + targRad
                let drSq = dr * dr
                
                if drSq > distSq {
                    colliderCount += 1
                    world.setComponent(entity: target, .Collider(radius: rad, count: colliderCount))
                    targetColliders[idx] = .Collider(radius: rad, count: colliderCount)
                }
                
                // Kill and spawn one
                if COLLISION_LIMIT > 0 && colliderCount > COLLISION_LIMIT {
                    if world.rmEntity(entity) {
                        targets.remove(at: idx)
                        deathCount += 1
                        break
                    }
                }
            }
        } // end entity query
        
        // Spawn new entities, one per each entity we deleted
        for _ in 0..<deathCount {
            world.createEntity(with: [
                .Position(Vec2(
                    MAX_POS * Float64.random(in: 0.0..<1.0),
                    MAX_POS * Float64.random(in: 0.0..<1.0)
                )),
                .Velocity(Vec2(
                    MAX_SPEED * Float64.random(in: 0.0..<1.0),
                    MAX_SPEED * Float64.random(in: 0.0..<1.0)
                )),
                .Collider(
                    radius: MAX_COLLIDER * Float64.random(in: 0.0..<1.0),
                    count: 0
                )
            ])
        } // endfor spawn per deathcount
        
        dt = start.timeIntervalSinceNow
        print(dt * -1000)
    }
}

main()

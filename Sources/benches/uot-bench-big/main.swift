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
    case FirstName(String)
    case LastName(String)
    case AltName(String)
    case UnitOfTimeSubscriberCount(UInt64)
    case PullRequests(UInt32)
    case HighScore(UInt32)
    case Size(Int64)
}

print("size:", MemoryLayout<Component>.size, "stride:", MemoryLayout<Component>.stride, "alignment:", MemoryLayout<Component>.alignment)

extension Component: ComponentCollection {
    static let count: Int = 10
    @inlinable
    static func id(_ c: Self) -> Int {
        switch c {
            case .Position: return Self.POSITION
            case .Velocity: return Self.VELOCITY
            case .Collider: return Self.COLLIDER
            case .FirstName: return Self.FIRST_NAME
            case .LastName: return Self.LAST_NAME
            case .AltName: return Self.ALT_NAME
            case .UnitOfTimeSubscriberCount: return Self.UOT_SUBS
            case .PullRequests: return Self.PULL_REQUESTS
            case .HighScore: return Self.HIGHSCORE
            case .Size: return Self.SIZE
        }
    }
}

// TODO: find a better solution than his
extension Component {
    static let POSITION = 0
    static let VELOCITY = 1
    static let COLLIDER = 2
    static let FIRST_NAME = 3
    static let LAST_NAME = 4
    static let ALT_NAME = 5
    static let UOT_SUBS = 6
    static let PULL_REQUESTS = 7
    static let HIGHSCORE = 8
    static let SIZE = 9
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
        world.createEntity(with: [
            .Position(Vec2(MAX_POS * Float64.random(in: 0.0..<1.0), MAX_POS * Float64.random(in: 0.0..<1.0))),
            .Velocity(Vec2(MAX_SPEED * Float64.random(in: 0.0..<1.0), MAX_SPEED * Float64.random(in: 0.0..<1.0))),
            .Collider(
                radius: MAX_COLLIDER * Float64.random(in: 0.0..<1.0),
                count: 0
            ),
            .FirstName("Henry"),
            .LastName("The Sixth"),
            .AltName("Jomy is better than Unit"),
            .UnitOfTimeSubscriberCount(0),
            .PullRequests(UInt32.random(in: 0..<UInt32.max)),
            .HighScore(UInt32.random(in: 0..<UInt32.max)),
            .Size(Int64.random(in: 0..<Int64.max)),
        ])
    }
    
    var start = Date()
    var dt = start.timeIntervalSinceNow
    let fixedTime = 0.015
    for _ in 0..<ITERATIONS {
        start = Date()
        
        // update positions
        world.query([Component.POSITION, Component.VELOCITY]) { (id, comps) in
            
            guard case .Velocity(var vel) = comps[Component.VELOCITY] else { fatalError("Found unexpected enum type for velocity") }
            guard case .Position(var pos) = comps[Component.POSITION] else { fatalError("Found unexpected enum type for position") }
            
            pos.x += vel.x * fixedTime
            pos.y += vel.y * fixedTime
            
            // Bump into the bounding rect
            if pos.x <= 0 || pos.x >= MAX_POS {
                vel.x = -vel.x
            }
            if pos.y <= 0 || pos.y >= MAX_POS {
                vel.y = -vel.y
            }
            
            world.setComponent(entity: id, .Velocity(vel))
            world.setComponent(entity: id, .Position(pos))
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
        
        world.query([Component.POSITION, Component.COLLIDER]) { (entity, components) in
            guard case .Position(let pos) = components[Component.POSITION] else { fatalError("Found unexpected enum type for target position") }
            guard case .Collider(radius: let rad, count: var colliderCount) = components[Component.COLLIDER] else { fatalError("Found unexpected enum type for target collider") }
            
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
                ),
                .FirstName("Henry"),
                .LastName("The Sixth"),
                .AltName("Jomy is better than Unit"),
                .UnitOfTimeSubscriberCount(0),
                .PullRequests(UInt32.random(in: 0..<UInt32.max)),
                .HighScore(UInt32.random(in: 0..<UInt32.max)),
                .Size(Int64.random(in: 0..<Int64.max)),
            ])
        } // endfor spawn per deathcount
        
        dt = start.timeIntervalSinceNow
        print(dt * -1000)
    }
}

main()

import Raylib
import kiwi

struct KeyboardLayout {
    let up: KeyboardKey
    let down: KeyboardKey
}

enum Component {
    case Position(Vector2)
    case Bounds(Vector2)
    case Velocity(Vector2)
    case Controllable(KeyboardLayout)
    case Drawable
    case Speed(Float)
}

extension Component: ComponentCollection {
    static let count = 6
    static func id(_ s: Self) -> Int {
        switch s {
            case .Position: return Self.POSITION
            case .Bounds: return Self.BOUNDS
            case .Velocity: return Self.VELOCITY
            case .Controllable: return Self.CONTROLLABLE
            case .Drawable: return Self.DRAWABLE
            case .Speed: return Self.SPEED
        }
    }
    static let POSITION = 0
    static let BOUNDS = 1
    static let VELOCITY = 2
    static let CONTROLLABLE = 3
    static let DRAWABLE = 4
    static let SPEED = 5
}

// constants
let SCREENW: Int32 = 800
let SCREENH: Int32 = 450

let PADDLE_PADDING: Float32 = 100
let PADDLEW: Float32 = 10
let PADDLEH: Float32 = 60

let BALL_SIZE: Float32 = 10
let BALL_SPEED: Float32 = 4

// Raylib setup
Raylib.setConfigFlags(.vsyncHint)
Raylib.initWindow(SCREENW, SCREENH, "kiwi - pong demo")
//Raylib.setTargetFPS(60)

// Create a new ecs world
var world: World<Component, Int8, Int8> = World();

// Add players to the world
world.createEntity(with: [
    .Controllable(KeyboardLayout(up: .letterW, down: .letterS)),
    .Position(Vector2(x: PADDLE_PADDING, y: Float(SCREENH) / 2 - PADDLEH / 2)),
    .Bounds(Vector2(x: PADDLEW, y: PADDLEH)),
    .Velocity(Vector2(x: 0, y: 0)),
    .Drawable,
    .Speed(200)
])

world.createEntity(with: [
    .Controllable(KeyboardLayout(up: .up, down: .down)),
    .Position(Vector2(x: Float(SCREENW) - PADDLE_PADDING, y: Float(SCREENH) / 2 - PADDLEH / 2)),
    .Bounds(Vector2(x: PADDLEW, y: PADDLEH)),
    .Velocity(Vector2(x: 0, y: 0)),
    .Drawable,
    .Speed(200)
])

// Add colliders below
let wallId1 = world.createEntity(with: [
    .Position(Vector2(x: 0, y: 0)),
    .Bounds(Vector2(x: Float(SCREENW), y: 1))
])
let wallId2 = world.createEntity(with: [
    .Position(Vector2(x: 0, y: Float(SCREENH) - 1)),
    .Bounds(Vector2(x: Float(SCREENW), y: 1))
])
world.setFlag(entity: wallId1, 2) // tag 2 = walls
world.setFlag(entity: wallId2, 2) // tag 2 = walls

// Add ball entity
let ballId = world.createEntity(with: [
    .Position(Vector2(x: Float(SCREENW) / 2 - BALL_SIZE / 2, y: Float(SCREENH) / 2 - BALL_SIZE / 2)),
    .Bounds(Vector2(x: BALL_SIZE, y: BALL_SIZE)),
    .Velocity(Vector2(x: -BALL_SPEED, y: 0)), // TODO: random
    .Drawable,
    .Speed(100)
])
// Add a flag to the ball entity to indicate that this is the ball
world.setFlag(entity: ballId, 1)

while !Raylib.windowShouldClose {
    //=========
    // Update
    //=========
    
    // This is where the systems go
    
    // Player input
    world.query([Component.CONTROLLABLE, Component.VELOCITY]) { (id, components) in
        guard case .Controllable(let layout) = components[Component.CONTROLLABLE] else { fatalError() }
        guard case .Velocity(var vel) = components[Component.VELOCITY] else { fatalError() }
        
        if Raylib.isKeyDown(layout.up) {
            if vel.y > 0 { vel = Vector2(x: 0, y: 0) }
            vel = Vector2(x: 0, y: max(vel.y - 0.125, -1))
        } else if Raylib.isKeyDown(layout.down) {
            if vel.y < 0 { vel = Vector2(x: 0, y: 0) }
            vel = Vector2(x: 0, y: min(vel.y + 0.125, 1))
        } else {
            vel = Vector2(x: 0, y: 0)
        }
        
        world.setComponent(entity: id, .Velocity(vel))
    }
    
    var gameOver = false
    // Collisions + check gameover
    // Get ball entity and check collisions
    world.readFlagsQuery(CollectionOfOne(1)) { (ballId, components) in
        guard case .Position(let bpos) = components[Component.POSITION] else { fatalError() }
        guard case .Velocity(var bvel) = components[Component.VELOCITY] else { fatalError() }
        guard case .Bounds(let bbounds) = components[Component.BOUNDS]  else { fatalError() }
        
        // check gameover
        if bpos.x < 0 || bpos.x > Float(SCREENW) {
            gameOver = true
        }
        
        world.query([Component.POSITION, Component.BOUNDS]) { (paddleId, components) in
            if ballId == paddleId { return } // skip if same entity
            guard case .Position(let ppos) = components[Component.POSITION] else { fatalError() }
            guard case .Bounds(let pbounds) = components[Component.BOUNDS]  else { fatalError() }
        
            if Raylib.checkCollisionRecs(
                Rectangle(x: bpos.x, y: bpos.y, width: bbounds.x, height: bbounds.y),
                Rectangle(x: ppos.x, y: ppos.y, width: pbounds.x, height: pbounds.y)
            ) {
                // collision detected

                if !world.readFlag(entity: paddleId, 2) {
                    bvel.x = bvel.x * -1
                
                    let colliderMiddle = ppos.y + pbounds.y / 2
                    if bpos.y > colliderMiddle + pbounds.y / 10 {
                        bvel.y = max(bvel.y + 0.1, 1)
                    } else if bpos.y < colliderMiddle - pbounds.y / 10 {
                        bvel.y = min(bvel.y - 0.1, -1)
                    }
                } else {
                    bvel.y = bvel.y * -1
                } 
                
                world.setComponent(entity: ballId, .Velocity(bvel))
            }
        }
    }
    
    // Move entities
    world.query([Component.POSITION, Component.VELOCITY, Component.BOUNDS, Component.SPEED]) { (id, components) in
        guard case .Position(var pos) = components[Component.POSITION] else { fatalError() }
        guard case .Velocity(let vel) = components[Component.VELOCITY] else { fatalError() }
        guard case .Bounds(let bounds) = components[Component.BOUNDS] else { fatalError() }
        guard case .Speed(let speed) = components[Component.SPEED] else { fatalError() }
        
        let delta = Raylib.getFrameTime()
        
        pos = Vector2(
            x: pos.x + vel.x * speed * delta, // min(max(0, pos.x + vel.x * speed * delta), Float(SCREENW) - bounds.x),
            y: min(max(0, pos.y + vel.y * speed * delta), Float(SCREENH) - bounds.y)
        )
        
        world.setComponent(entity: id, .Position(pos))
    }
    
    //=========
    // Drawing
    //=========
    Raylib.beginDrawing()
    Raylib.clearBackground(.black)
    
    // Draw objects
    world.query([Component.POSITION, Component.BOUNDS, Component.DRAWABLE]) { (id, components) in
        guard case .Position(let pos) = components[Component.POSITION] else { fatalError() }
        guard case .Bounds(let bounds) = components[Component.BOUNDS] else { fatalError() }
        
        Raylib.drawRectangleV(pos, bounds, .white)
    }
    
    if gameOver {
        let fontSize: Int32 = 60
        let text = "Game Over"
        let textSize = Raylib.measureTextEx(Raylib.getFontDefault(), "Game Over", Float(fontSize), 60 / 10)
        let textX = SCREENW / 2 - Int32(textSize.x) / 2
        let textY = SCREENH / 2 - Int32(textSize.y) / 2
        Raylib.drawText(text, textX, textY, fontSize, .white)
    }
    
    Raylib.endDrawing()
}

Raylib.closeWindow()


extension Vector2 {
    static func /(lhs: Self, rhs: Float) -> Vector2 {
        Vector2(x: lhs.x / rhs, y: lhs.y / rhs)
    }
    static func *(lhs: Float, rhs: Self) -> Vector2 {
        Vector2(x: lhs * rhs.x, y: lhs * rhs.y)
    }
}

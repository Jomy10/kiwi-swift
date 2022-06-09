//=========================================================//
// This benchmark is related to internal performance tests //
//=========================================================//

import Benchmark

fileprivate typealias Arr = ArraySlice

fileprivate enum Component {
    case One(Int)
}

fileprivate final class Ref {
    final var arr: Arr<Component>
    
    init(_ arr: Arr<Component>) {
        self.arr = arr
    }
}

struct World1 {
    
}

fileprivate struct World2 {
    let arr: Ref
    
}

internal func mutClosureBench() -> BenchmarkSuite {
    let mutBench = BenchmarkSuite(name: "Mutable Closure Benches", settings: Iterations(100000), WarmupIterations(10000)) { suite in
    }
    
    return mutBench
}

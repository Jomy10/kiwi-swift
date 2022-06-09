import Foundation
import Benchmark

var benches: [BenchmarkSuite] = []

if let _ = ProcessInfo.processInfo.environment["MUTQUERY"] {
    benches.append(mutQueryBench())
}
if let ProcessInfo.processInfo.environment["DOUBLEQUERY"] {
    benches.append(doubleQuery())
}
if let _ = ProcessInfo.processInfo.environment["MUTCLOSURE"] {
    benches.append(mutClosureBench())
}

Benchmark.main(benches)

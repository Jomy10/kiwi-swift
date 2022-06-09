import Foundation
import Benchmark

var benches: [BenchmarkSuite] = []

if let _ = ProcessInfo.processInfo.environment["MUTQUERY"] {
    benches.append(mutQueryBench())
}

Benchmark.main(benches)

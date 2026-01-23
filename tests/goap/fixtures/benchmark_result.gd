## Data structure for benchmark results.
##
## Provides structured storage and comparison for benchmark metrics.[br]
## Used by test_goap_benchmarks.gd for performance tracking.[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## var result := BenchmarkResult.new("test_name", 1000, 5.5, 0.1, 0.05, 10.0)
## print(result.summary())
## [/codeblock]
class_name BenchmarkResult
extends RefCounted


## Name of the benchmark test.
var test_name: StringName

## Number of iterations run.
var iterations: int

## Total time in milliseconds (max after sorting).
var total_ms: float

## Average/median time in milliseconds.
var avg_ms: float

## Minimum time in milliseconds.
var min_ms: float

## Maximum time in milliseconds.
var max_ms: float

## Target time in milliseconds for pass/fail.
var target_ms: float


func _init(
	p_test_name: StringName,
	p_iterations: int,
	p_total: float,
	p_avg: float,
	p_min: float,
	p_max: float,
	p_target: float = 0.0
) -> void:
	test_name = p_test_name
	iterations = p_iterations
	total_ms = p_total
	avg_ms = p_avg
	min_ms = p_min
	max_ms = p_max
	target_ms = p_target


## Creates a BenchmarkResult from timing array.
static func from_times(
	p_test_name: StringName,
	times: Array[float],
	p_target: float = 0.0
) -> BenchmarkResult:
	times.sort()
	var iter := times.size()
	var total := times[-1] if iter > 0 else 0.0
	var avg := times[iter / 2.0] if iter > 0 else 0.0
	var min_time := times[0] if iter > 0 else 0.0
	var max_time := times[-1] if iter > 0 else 0.0

	return BenchmarkResult.new(p_test_name, iter, total, avg, min_time, max_time, p_target)


## Returns whether benchmark passed target.
func passed() -> bool:
	if target_ms <= 0.0:
		return true
	return avg_ms <= target_ms


## Returns summary string for logging.
func summary() -> String:
	return "%s: avg=%.2fms, min=%.2fms, max=%.2fms, target=%.2fms (%s)" % [
		test_name,
		avg_ms,
		min_ms,
		max_ms,
		target_ms,
		"PASS" if passed() else "FAIL"
	]


## Returns detailed stats string.
func detailed() -> String:
	return "%s\n  Iterations: %d\n  Avg: %.4fms\n  Min: %.4fms\n  Max: %.4fms\n  Target: %.4fms\n  Status: %s" % [
		test_name,
		iterations,
		avg_ms,
		min_ms,
		max_ms,
		target_ms,
		"PASSED" if passed() else "FAILED"
	]


## Returns performance rating based on target.
func rating() -> String:
	if target_ms <= 0.0:
		return "N/A"
	var ratio := avg_ms / target_ms
	if ratio <= 0.5:
		return "EXCELLENT"
	elif ratio <= 0.8:
		return "GOOD"
	elif ratio <= 1.0:
		return "ACCEPTABLE"
	elif ratio <= 1.5:
		return "SLOW"
	else:
		return "REGRESSION"


## Creates comparison with another result.
func compare(other: BenchmarkResult) -> Dictionary:
	var avg_change := other.avg_ms - avg_ms
	var avg_percent := (avg_change / avg_ms * 100.0) if avg_ms > 0 else 0.0

	return {
		"test_name": test_name,
		"avg_before": avg_ms,
		"avg_after": other.avg_ms,
		"avg_change_ms": avg_change,
		"avg_change_percent": avg_percent,
		"rating_before": rating(),
		"rating_after": other.rating(),
		"improved": avg_change < 0,
		"regressed": avg_change > 0 and avg_percent > 10.0
	}


## Exports result as dictionary for serialization.
func to_dict() -> Dictionary:
	return {
		&"test_name": test_name,
		&"iterations": iterations,
		&"total_ms": total_ms,
		&"avg_ms": avg_ms,
		&"min_ms": min_ms,
		&"max_ms": max_ms,
		&"target_ms": target_ms,
		&"passed": passed(),
		&"rating": rating()
	}


## Creates result from dictionary.
static func from_dict(data: Dictionary) -> BenchmarkResult:
	return BenchmarkResult.new(
		data.get(&"test_name", &""),
		data.get(&"iterations", 0),
		data.get(&"total_ms", 0.0),
		data.get(&"avg_ms", 0.0),
		data.get(&"min_ms", 0.0),
		data.get(&"max_ms", 0.0),
		data.get(&"target_ms", 0.0)
	)

package main

import "core:math"

interval :: struct {
	min, max: f64,
}

interval_size :: proc(i: interval) -> f64 {
	return i.max - i.min
}

interval_contains :: proc(i: interval, x: f64) -> bool {
	return i.min <= x && x <= i.max
}

interval_surrounds :: proc(i: interval, x: f64) -> bool {
	return i.min < x && x < i.max
}

interval_clamp :: proc(i: interval, x: f64) -> f64 {
	if x < i.min {
		return i.min
	}

	if x > i.max {
		return i.max
	}

	return x
}

INTERVAL_EMPTY :: interval{math.F64_MAX, -math.F64_MAX}
INTERVAL_UNIVERSE :: interval{-math.F64_MAX, math.F64_MAX}


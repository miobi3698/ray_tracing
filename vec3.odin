package main

import "core:math"

vec3 :: [3]f64

point3 :: vec3

vec3_length :: proc(v: vec3) -> f64 {
	return math.sqrt(vec3_dot(v, v))
}

vec3_near_zero :: proc(v: vec3) -> bool {
	s := 1e-8
	return (math.abs(v.x) < s) && (math.abs(v.y) < s) && (math.abs(v.z) < s)
}

vec3_div :: proc(v: vec3, t: f64) -> vec3 {
	return v * (1.0 / t)
}

vec3_dot :: proc(u, v: vec3) -> f64 {
	return u.x * v.x + u.y * v.y + u.z * v.z
}

vec3_cross :: proc(u, v: vec3) -> vec3 {
	return {u.y * v.z - u.z * v.y, u.z * v.x - u.x * v.z, u.x * v.y - u.y * v.x}
}

vec3_norm :: proc(v: vec3) -> vec3 {
	return v / vec3_length(v)
}

vec3_random :: proc() -> vec3 {
	return vec3{random_f64(), random_f64(), random_f64()}
}

vec3_random_range :: proc(min, max: f64) -> vec3 {
	return vec3{random_f64_range(min, max), random_f64_range(min, max), random_f64_range(min, max)}
}

vec3_random_unit_vector :: proc() -> vec3 {
	for {
		p := vec3_random_range(-1, 1)
		lensq := vec3_dot(p, p)
		if 1e-160 < lensq && lensq <= 1 {
			return vec3_div(p, math.sqrt(lensq))
		}
	}
}

vec3_random_on_hemisphere :: proc(normal: vec3) -> vec3 {
	on_unit_sphere := vec3_random_unit_vector()
	if vec3_dot(on_unit_sphere, normal) > 0.0 {
		return on_unit_sphere
	} else {
		return -on_unit_sphere
	}
}

vec3_reflect :: proc(v, n: vec3) -> vec3 {
	return v - n * 2 * vec3_dot(v, n)
}

vec3_refract :: proc(uv, n: vec3, etai_over_etat: f64) -> vec3 {
	cos_theta := min(vec3_dot(-uv, n), 1)
	r_out_perp := (uv + n * cos_theta) * etai_over_etat
	r_out_parallel := n * -math.sqrt(abs(1.0 - vec3_dot(r_out_perp, r_out_perp)))
	return r_out_perp + r_out_parallel
}


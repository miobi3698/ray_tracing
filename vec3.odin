package main

import "core:math"

vec3 :: [3]f64

point3 :: vec3

vec3_length :: proc(v: vec3) -> f64 {
  return math.sqrt(vec3_dot(v, v))
}

vec3_div :: proc(v: vec3, t: f64) -> vec3 {
  return v * (1.0 / t)
}

vec3_dot :: proc(u, v: vec3) -> f64 {
  return u.x * v.x + u.y * v.y + u.z * v.z
}

vec3_cross :: proc(u, v: vec3) -> vec3 {
  return {
    u.y * v.z - u.z * v.y,
    u.z * v.x - u.x * v.z,
    u.x * v.y - u.y * v.x,
  }
}

vec3_norm :: proc(v: vec3) -> vec3 {
  return v / vec3_length(v)
}

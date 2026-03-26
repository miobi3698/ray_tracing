package main

ray :: struct {
  origin: point3,
  direction: vec3,
}

ray_at :: proc(r: ray, t: f64) -> point3 {
  return r.origin + t * r.direction
}

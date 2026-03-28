package main

import "core:math"

hit_record :: struct {
	p:          point3,
	normal:     vec3,
	mat:        material,
	t:          f64,
	front_face: bool,
}

hit_record_set_face_normal :: proc(rec: ^hit_record, r: ray, outward_normal: vec3) {
	rec.front_face = vec3_dot(r.direction, outward_normal) < 0
	if rec.front_face {
		rec.normal = outward_normal
	} else {
		rec.normal = -outward_normal
	}
}

hittable :: union {
	[]hittable,
	sphere,
}

hit :: proc(object: hittable, r: ray, ray_t: interval, rec: ^hit_record) -> bool {
	switch o in object {
	case sphere:
		return sphere_hit(o, r, ray_t, rec)
	case []hittable:
		return hittable_list_hit(o, r, ray_t, rec)
	}

	return false
}

sphere :: struct {
	center: point3,
	radius: f64,
	mat:    material,
}

sphere_hit :: proc(o: sphere, r: ray, ray_t: interval, rec: ^hit_record) -> bool {
	oc := o.center - r.origin
	a := vec3_dot(r.direction, r.direction)
	h := vec3_dot(r.direction, oc)
	c := vec3_dot(oc, oc) - o.radius * o.radius
	discriminant := h * h - a * c
	if discriminant < 0 {
		return false
	}

	sqrtd := math.sqrt(discriminant)

	root := (h - sqrtd) / a
	if !interval_surrounds(ray_t, root) {
		root = (h + sqrtd) / a
		if !interval_surrounds(ray_t, root) {
			return false
		}
	}

	rec.t = root
	rec.p = ray_at(r, rec.t)
	outward_normal := (rec.p - o.center) / o.radius
	hit_record_set_face_normal(rec, r, outward_normal)
	rec.mat = o.mat
	return true
}

hittable_list_hit :: proc(objects: []hittable, r: ray, ray_t: interval, rec: ^hit_record) -> bool {
	temp_rec := hit_record{}
	hit_anything := false
	closest_so_far := ray_t.max

	for object in objects {
		if hit(object, r, interval{ray_t.min, closest_so_far}, &temp_rec) {
			hit_anything = true
			closest_so_far = temp_rec.t
			rec^ = temp_rec
		}
	}

	return hit_anything
}


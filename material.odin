package main

import "core:math"

material :: union {
	lambertian,
	metal,
	dielectric,
}

scatter :: proc(
	mat: material,
	r_in: ray,
	rec: hit_record,
	attenuation: ^color,
	scattered: ^ray,
) -> bool {
	switch m in mat {
	case lambertian:
		return lambertian_scatter(m, r_in, rec, attenuation, scattered)
	case metal:
		return metal_scatter(m, r_in, rec, attenuation, scattered)
	case dielectric:
		return dielectric_scatter(m, r_in, rec, attenuation, scattered)
	}

	return false
}

lambertian :: struct {
	albedo: color,
}

lambertian_scatter :: proc(
	mat: lambertian,
	r_in: ray,
	rec: hit_record,
	attenuation: ^color,
	scattered: ^ray,
) -> bool {
	scatter_direction := rec.normal + vec3_random_unit_vector()

	if vec3_near_zero(scatter_direction) {
		scatter_direction = rec.normal
	}

	scattered^ = ray{rec.p, scatter_direction}
	attenuation^ = mat.albedo
	return true
}

metal :: struct {
	albedo: color,
	fuzz:   f64,
}

metal_scatter :: proc(
	mat: metal,
	r_in: ray,
	rec: hit_record,
	attenuation: ^color,
	scattered: ^ray,
) -> bool {
	reflected :=
		vec3_norm(vec3_reflect(r_in.direction, rec.normal)) +
		(vec3_random_unit_vector() * mat.fuzz)
	scattered^ = ray{rec.p, reflected}
	attenuation^ = mat.albedo
	return vec3_dot(scattered.direction, rec.normal) > 0
}

dielectric :: struct {
	refraction_index: f64,
}

dielectric_scatter :: proc(
	mat: dielectric,
	r_in: ray,
	rec: hit_record,
	attenuation: ^color,
	scattered: ^ray,
) -> bool {
	attenuation^ = color{1, 1, 1}
	ri := mat.refraction_index if rec.front_face else 1.0 / mat.refraction_index

	unit_direction := vec3_norm(r_in.direction)
	cos_theta := min(vec3_dot(-unit_direction, rec.normal), 1)
	sin_theta := math.sqrt(1.0 - cos_theta * cos_theta)

	cannot_refract := ri * sin_theta > 1
	direction :=
		vec3_reflect(unit_direction, rec.normal) if cannot_refract || reflectance(cos_theta, ri) > random_f64() else vec3_refract(unit_direction, rec.normal, ri)

	scattered^ = ray{rec.p, direction}
	return true
}

reflectance :: proc(cosine: f64, refraction_index: f64) -> f64 {
	r0 := (1 - refraction_index) / (1 + refraction_index)
	r0 = r0 * r0
	return r0 + (1 - r0) * math.pow(1 - cosine, 5)
}


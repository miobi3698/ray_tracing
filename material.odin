package main

material :: union {
	lambertian,
	metal,
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
		return lambertial_scatter(m, r_in, rec, attenuation, scattered)
	case metal:
		return metal_scatter(m, r_in, rec, attenuation, scattered)
	}

	return false
}

lambertian :: struct {
	albedo: color,
}

lambertial_scatter :: proc(
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


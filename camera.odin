package main

import "core:math"
import rl "vendor:raylib"

camera :: struct {
	aspect_ratio:       f64,
	image_width:        int,
	image_height:       int,
	samples_per_pixel:  int,
	max_depth:          int,
	vfov:               f64,
	lookfrom:           point3,
	lookat:             point3,
	vup:                vec3,
	pixel_sample_scale: f64,
	center:             point3,
	pixel00_loc:        point3,
	pixel_delta_u:      vec3,
	pixel_delta_v:      vec3,
	u, v, w:            vec3,
}

camera_new :: proc(
	aspect_ratio: f64,
	image_width: int,
	samples_per_pixel: int,
	max_depth: int,
	vfov: f64,
	lookfrom, lookat: point3,
	vup: vec3,
) -> camera {
	image_height := int(f64(image_width) / aspect_ratio)
	pixel_sample_scale := 1.0 / f64(samples_per_pixel)
	center := lookfrom

	focal_length := vec3_length(lookfrom - lookat)
	theta := degrees_to_radians(vfov)
	h := math.tan(theta / 2)
	viewport_height := 2 * h * focal_length
	viewport_width := viewport_height * aspect_ratio

	w := vec3_norm(lookfrom - lookat)
	u := vec3_norm(vec3_cross(vup, w))
	v := vec3_cross(w, u)

	viewport_u := u * viewport_width
	viewport_v := -v * viewport_height

	pixel_delta_u := viewport_u / f64(image_width)
	pixel_delta_v := viewport_v / f64(image_height)

	viewport_upper_left := center - w * focal_length - viewport_u / 2 - viewport_v / 2
	pixel00_loc := viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v)

	return camera {
		aspect_ratio,
		image_width,
		image_height,
		samples_per_pixel,
		max_depth,
		vfov,
		lookfrom,
		lookat,
		vup,
		pixel_sample_scale,
		center,
		pixel00_loc,
		pixel_delta_u,
		pixel_delta_v,
		u,
		v,
		w,
	}
}

camera_render :: proc(c: camera, world: hittable) -> rl.RenderTexture2D {
	render_texture := rl.LoadRenderTexture(i32(c.image_width), i32(c.image_height))
	rl.BeginTextureMode(render_texture)
	for j in 0 ..< c.image_height {
		for i in 0 ..< c.image_width {
			pixel_color := color{}

			for sample in 0 ..< c.samples_per_pixel {
				r := camera_get_ray(c, i, j)
				pixel_color += ray_color(r, c.max_depth, world)
			}
			write_color(i, c.image_height - j - 1, pixel_color * c.pixel_sample_scale)
		}

		rl.TraceLog(.INFO, "Scanlines remaining: %d", c.image_height - j)
	}
	rl.TraceLog(.INFO, "Done.")
	rl.EndTextureMode()

	return render_texture
}

camera_get_ray :: proc(c: camera, i, j: int) -> ray {
	offset := sample_square()
	pixel_sample :=
		c.pixel00_loc +
		(c.pixel_delta_u * (f64(i) + offset.x)) +
		(c.pixel_delta_v * (f64(j) + offset.y))

	return ray{c.center, pixel_sample - c.center}
}

sample_square :: proc() -> vec3 {
	return vec3{random_f64() - 0.5, random_f64() - 0.5, 0}
}

color :: vec3

ray_color :: proc(r: ray, depth: int, world: hittable) -> color {
	if depth <= 0 {
		return {}
	}

	rec := hit_record{}
	if hit(world, r, interval{0.001, math.F64_MAX}, &rec) {
		scattered := ray{}
		attenuation := color{}
		if scatter(rec.mat, r, rec, &attenuation, &scattered) {
			return attenuation * ray_color(scattered, depth - 1, world)
		}

		return {}
		// direction := rec.normal + vec3_random_unit_vector()
		// return ray_color(ray{rec.p, direction}, depth - 1, world) * 0.5
	}

	unit_direction := vec3_norm(r.direction)
	a := 0.5 * (unit_direction.y + 1)
	return color{1, 1, 1} * (1.0 - a) + color{0.5, 0.7, 1} * a
}

color_intensity :: interval{0.000, 0.999}

linear_to_gamma :: proc(linear_component: f64) -> f64 {
	if linear_component > 0 {
		return math.sqrt(linear_component)
	}

	return 0
}

write_color :: proc(x, y: int, pixel_color: color) {
	r := linear_to_gamma(pixel_color.r)
	g := linear_to_gamma(pixel_color.g)
	b := linear_to_gamma(pixel_color.b)

	ir := u8(256 * interval_clamp(color_intensity, r))
	ig := u8(256 * interval_clamp(color_intensity, g))
	ib := u8(256 * interval_clamp(color_intensity, b))

	rl.DrawPixel(i32(x), i32(y), {ir, ig, ib, 255})
}


package main

import "core:math"
import rl "vendor:raylib"

camera :: struct {
	aspect_ratio:       f64,
	image_width:        int,
	image_height:       int,
	samples_per_pixel:  int,
	pixel_sample_scale: f64,
	center:             point3,
	pixel00_loc:        point3,
	pixel_delta_u:      vec3,
	pixel_delta_v:      vec3,
}

camera_new :: proc(aspect_ratio: f64, image_width: int, samples_per_pixel: int) -> camera {
	image_height := int(f64(image_width) / aspect_ratio)
	pixel_sample_scale := 1.0 / f64(samples_per_pixel)

	focal_length := 1.0
	viewport_height := 2.0
	viewport_width := viewport_height * aspect_ratio
	center := point3{0, 0, 0}

	viewport_u := vec3{viewport_width, 0, 0}
	viewport_v := vec3{0, -viewport_height, 0}

	pixel_delta_u := vec3_div(viewport_u, f64(image_width))
	pixel_delta_v := vec3_div(viewport_v, f64(image_height))

	viewport_upper_left := center - vec3{0, 0, focal_length} - viewport_u / 2 - viewport_v / 2
	pixel00_loc := viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v)

	return camera {
		aspect_ratio,
		image_width,
		image_height,
		samples_per_pixel,
		pixel_sample_scale,
		center,
		pixel00_loc,
		pixel_delta_u,
		pixel_delta_v,
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
				pixel_color += ray_color(r, world)
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

ray_color :: proc(r: ray, world: hittable) -> color {
	rec := hit_record{}
	if hit(world, r, interval{0, math.F64_MAX}, &rec) {
		return (rec.normal + color{1, 1, 1}) * 0.5
	}

	unit_direction := vec3_norm(r.direction)
	a := 0.5 * (unit_direction.y + 1)
	return color{1, 1, 1} * (1.0 - a) + color{0.5, 0.7, 1} * a
}

color_intensity :: interval{0.000, 0.999}

write_color :: proc(x, y: int, pixel_color: color) {
	ir := u8(256 * interval_clamp(color_intensity, pixel_color.r))
	ig := u8(256 * interval_clamp(color_intensity, pixel_color.g))
	ib := u8(256 * interval_clamp(color_intensity, pixel_color.b))

	rl.DrawPixel(i32(x), i32(y), {ir, ig, ib, 255})
}


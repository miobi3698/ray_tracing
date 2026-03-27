package main

import "core:math"
import rl "vendor:raylib"

camera :: struct {
	aspect_ratio:  f64,
	image_width:   int,
	image_height:  int,
	center:        point3,
	pixel00_loc:   point3,
	pixel_delta_u: vec3,
	pixel_delta_v: vec3,
}

camera_new :: proc(aspect_ratio: f64, image_width: int) -> camera {
	image_height := int(f64(image_width) / aspect_ratio)

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
			pixel_center := c.pixel00_loc + (c.pixel_delta_u * f64(i)) + (c.pixel_delta_v * f64(j))
			ray_direction := pixel_center - c.center
			r := ray{c.center, ray_direction}
			pixel_color := camera_ray_color(r, world)
			camera_write_color(i, c.image_height - j - 1, pixel_color)
		}

		rl.TraceLog(.INFO, "Scanlines remaining: %d", c.image_height - j)
	}
	rl.TraceLog(.INFO, "Done.")
	rl.EndTextureMode()

	return render_texture
}

color :: vec3

camera_ray_color :: proc(r: ray, world: hittable) -> color {
	rec := hit_record{}
	if hit(world, r, interval{0, math.F64_MAX}, &rec) {
		return (rec.normal + color{1, 1, 1}) * 0.5
	}

	unit_direction := vec3_norm(r.direction)
	a := 0.5 * (unit_direction.y + 1)
	return color{1, 1, 1} * (1.0 - a) + color{0.5, 0.7, 1} * a
}

camera_write_color :: proc(x, y: int, pixel_color: color) {
	ir := u8(255.999 * pixel_color.r)
	ig := u8(255.999 * pixel_color.g)
	ib := u8(255.999 * pixel_color.b)

	rl.DrawPixel(i32(x), i32(y), {ir, ig, ib, 255})
}


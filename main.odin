package main

import "core:math"
import rl "vendor:raylib"

main :: proc() {
	// Image
	aspect_ratio := 16.0 / 9
	image_width := i32(400)
	image_height := i32(f64(image_width) / aspect_ratio)

	// World
	world := []hittable{sphere{point3{0, 0, -1}, 0.5}, sphere{point3{0, -100.5, -1}, 100}}

	// Camera
	focal_length := 1.0
	viewport_height := 2.0
	viewport_width := viewport_height * aspect_ratio
	camera_center := point3{0, 0, 0}

	viewport_u := vec3{viewport_width, 0, 0}
	viewport_v := vec3{0, -viewport_height, 0}

	pixel_delta_u := vec3_div(viewport_u, f64(image_width))
	pixel_delta_v := vec3_div(viewport_v, f64(image_height))

	viewport_upper_left :=
		camera_center - vec3{0, 0, focal_length} - viewport_u / 2 - viewport_v / 2
	pixel00_loc := viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v)

	rl.InitWindow(image_width, image_height, "Ray Tracing in One Weekend")
	defer rl.CloseWindow()

	render_texture := rl.LoadRenderTexture(image_width, image_height)
	rl.BeginTextureMode(render_texture)
	for j in 0 ..< image_height {
		for i in 0 ..< image_width {
			pixel_center := pixel00_loc + (pixel_delta_u * f64(i)) + (pixel_delta_v * f64(j))
			ray_direction := pixel_center - camera_center
			r := ray{camera_center, ray_direction}
			pixel_color := ray_color(r, world)
			write_color(i, image_height - j - 1, pixel_color)
		}

		rl.TraceLog(.INFO, "Scanlines remaining: %d", image_height - j)
	}
	rl.EndTextureMode()
	rl.TraceLog(.INFO, "Done.")

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.DrawTexture(render_texture.texture, 0, 0, rl.WHITE)
		rl.EndDrawing()
	}
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

hit_sphere :: proc(center: point3, radius: f64, r: ray) -> f64 {
	oc := center - r.origin
	a := vec3_dot(r.direction, r.direction)
	h := vec3_dot(r.direction, oc)
	c := vec3_dot(oc, oc) - radius * radius
	discriminant := h * h - a * c
	if discriminant < 0 {
		return -1
	} else {
		return (h - math.sqrt(discriminant)) / a
	}
}

write_color :: proc(x, y: i32, pixel_color: color) {
	ir := u8(255.999 * pixel_color.r)
	ig := u8(255.999 * pixel_color.g)
	ib := u8(255.999 * pixel_color.b)

	rl.DrawPixel(i32(x), i32(y), {ir, ig, ib, 255})
}


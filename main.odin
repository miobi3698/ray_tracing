package main

import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

main :: proc() {
	world := []hittable{sphere{point3{0, 0, -1}, 0.5}, sphere{point3{0, -100.5, -1}, 100}}
	aspect_ratio := 16.0 / 9
	image_width := 400
	samples_per_pixel := 100
	max_depth := 50
	cam := camera_new(aspect_ratio, image_width, samples_per_pixel, max_depth)

	rl.InitWindow(i32(cam.image_width), i32(cam.image_height), "Ray Tracing in One Weekend")
	defer rl.CloseWindow()

	render_texture := camera_render(cam, world)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.DrawTexture(render_texture.texture, 0, 0, rl.WHITE)
		rl.EndDrawing()
	}
}

degrees_to_radians :: proc(degrees: f64) -> f64 {
	return degrees * math.PI / 180
}

random_f64 :: proc() -> f64 {
	return rand.float64()
}

random_f64_range :: proc(min, max: f64) -> f64 {
	return min + (max - min) * rand.float64()
}


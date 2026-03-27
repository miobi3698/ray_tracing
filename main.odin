package main

import rl "vendor:raylib"

main :: proc() {
	world := []hittable{sphere{point3{0, 0, -1}, 0.5}, sphere{point3{0, -100.5, -1}, 100}}
	cam := camera_new(16.0 / 9, 400)

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


package main

import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

main :: proc() {
	world := [dynamic]hittable{}

	ground_material := lambertian{color{0.5, 0.5, 0.5}}
	append(&world, sphere{point3{0, -1000, 0}, 1000, ground_material})

	for a in -11 ..< 11 {
		for b in -11 ..< 11 {
			choose_mat := random_f64()
			center := point3{f64(a) + 0.9 * random_f64(), 0.2, f64(b) + 0.9 * random_f64()}

			if vec3_length(center - point3{4, 0.2, 0}) > 0.9 {
				sphere_material: material

				if choose_mat < 0.8 {
					sphere_material = lambertian{vec3_random() * vec3_random()}
				} else if choose_mat < 0.95 {
					sphere_material = metal{vec3_random_range(0.5, 1), random_f64_range(0, 0.5)}
				} else {
					sphere_material = dielectric{1.5}
				}

				append(&world, sphere{center, 0.2, sphere_material})
			}
		}
	}

	append(&world, sphere{point3{0, 1, 0}, 1.0, dielectric{1.5}})
	append(&world, sphere{point3{-4, 1, 0}, 1.0, lambertian{color{0.4, 0.2, 0.1}}})
	append(&world, sphere{point3{4, 1, 0}, 1.0, metal{color{0.7, 0.6, 0.5}, 0.0}})

	cam := camera_new(
	{
		aspect_ratio      = 16.0 / 9,
		image_width       = 1200,
		samples_per_pixel = 10, // 500
		max_depth         = 50,
		vfov              = 20,
		lookfrom          = point3{13, 2, 3},
		lookat            = point3{},
		vup               = vec3{0, 1, 0},
		defocus_angle     = 0.6,
		focus_dist        = 10,
	},
	)

	pixel_buffer := make([]rl.Color, cam.image_width * cam.image_height)
	defer delete(pixel_buffer)
	camera_render(&pixel_buffer, cam, world[:])

	rl.InitWindow(i32(cam.image_width), i32(cam.image_height), "Ray Tracing in One Weekend")
	defer rl.CloseWindow()

	render_texture := rl.LoadRenderTexture(i32(cam.image_width), i32(cam.image_height))
	rl.BeginTextureMode(render_texture)
	for y in 0 ..< cam.image_height {
		for x in 0 ..< cam.image_width {
			rl.DrawPixel(i32(x), i32(y), pixel_buffer[x + y * cam.image_width])
		}
	}
	rl.EndTextureMode()

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


package main

import rl "vendor:raylib"

main :: proc() {
  // Image
  aspect_ratio := 16.0 / 9
  image_width := i32(400)
  image_height := i32(f64(image_width) / aspect_ratio)

  // Camera
  focal_length := 1.0
  viewport_height := 2.0
  viewport_width := viewport_height * aspect_ratio
  camera_center := point3{0, 0, 0}

  viewport_u := vec3{viewport_width, 0, 0}
  viewport_v := vec3{0, -viewport_width, 0}

  pixel_delta_u := vec3_div(viewport_u, f64(image_width))
  pixel_delta_v := vec3_div(viewport_v, f64(image_height))

  viewport_upper_left := camera_center - vec3{0, 0, focal_length} - viewport_u/2 - viewport_v/2
  pixel00_loc := viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v)

  rl.InitWindow(image_width, image_height, "Ray Tracing in One Weekend")
  defer rl.CloseWindow()

  render_texture := rl.LoadRenderTexture(image_width, image_height)
  rl.BeginTextureMode(render_texture)
  for j in 0..<image_height {
    for i in 0..<image_width {
      pixel_center := pixel00_loc + (pixel_delta_u * f64(i)) + (pixel_delta_v * f64(j))
      ray_direction := pixel_center - camera_center
      r := ray{camera_center, ray_direction}
      pixel_color := ray_color(r)
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

ray_color :: proc(r: ray) -> color {
  unit_direction := vec3_norm(r.direction)
  a := 0.5 * (unit_direction.y + 1)
  return color{1, 1, 1} * (1.0 - a) + color{0.5, 0.7, 1} * a
}

write_color :: proc(x, y: i32, pixel_color: color) {
  ir := u8(255.999 * pixel_color.r)
  ig := u8(255.999 * pixel_color.g)
  ib := u8(255.999 * pixel_color.b)

  rl.DrawPixel(i32(x), i32(y), {ir, ig, ib, 255})
}

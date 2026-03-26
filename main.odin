package main

import rl "vendor:raylib"

IMAGE_WIDTH :: 256
IMAGE_HEIGHT :: 256

main :: proc() {
  rl.InitWindow(IMAGE_WIDTH, IMAGE_HEIGHT, "Ray Tracing in One Weekend")
  defer rl.CloseWindow()

  render_texture := rl.LoadRenderTexture(IMAGE_WIDTH, IMAGE_HEIGHT)
  rl.BeginTextureMode(render_texture)
  for j in 0..<IMAGE_HEIGHT {
    for i in 0..<IMAGE_WIDTH {
      r := f64(i) / (IMAGE_WIDTH - 1)
      g := f64(j) / (IMAGE_HEIGHT - 1)
      b := 0.0

      ir := u8(255.999 * r)
      ig := u8(255.999 * g)
      ib := u8(255.999 * b)

      rl.DrawPixel(i32(i), i32(IMAGE_HEIGHT - j - 1), {ir, ig, ib, 255})
    }
    rl.TraceLog(.INFO, "Scanlines remaining: %d", IMAGE_HEIGHT - j)
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

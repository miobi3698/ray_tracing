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
	defocus_angle:      f64,
	focus_dist:         f64,
	pixel_sample_scale: f64,
	center:             point3,
	pixel00_loc:        point3,
	pixel_delta_u:      vec3,
	pixel_delta_v:      vec3,
	u, v, w:            vec3,
	defocus_disk_u:     vec3,
	defocus_disk_v:     vec3,
}

camera_config :: struct {
	aspect_ratio:      f64,
	image_width:       int,
	samples_per_pixel: int,
	max_depth:         int,
	vfov:              f64,
	lookfrom:          point3,
	lookat:            point3,
	vup:               vec3,
	defocus_angle:     f64,
	focus_dist:        f64,
}

camera_default_config :: camera_config {
	aspect_ratio      = 1.0,
	image_width       = 100,
	samples_per_pixel = 10,
	max_depth         = 10,
	vfov              = 90,
	lookfrom          = point3{},
	lookat            = point3{0, 0, -1},
	vup               = vec3{0, 1, 0},
	defocus_angle     = 0,
	focus_dist        = 10,
}

camera_new :: proc(config: camera_config) -> camera {
	c := camera{}

	c.aspect_ratio = config.aspect_ratio
	c.image_width = config.image_width
	c.samples_per_pixel = config.samples_per_pixel
	c.max_depth = config.max_depth

	c.vfov = config.vfov
	c.lookfrom = config.lookfrom
	c.lookat = config.lookat
	c.vup = config.vup

	c.defocus_angle = config.defocus_angle
	c.focus_dist = config.focus_dist

	c.image_height = int(f64(c.image_width) / c.aspect_ratio)
	c.pixel_sample_scale = 1.0 / f64(c.samples_per_pixel)
	c.center = c.lookfrom

	theta := degrees_to_radians(c.vfov)
	h := math.tan(theta / 2)
	viewport_height := 2 * h * c.focus_dist
	viewport_width := viewport_height * c.aspect_ratio

	c.w = vec3_norm(c.lookfrom - c.lookat)
	c.u = vec3_norm(vec3_cross(c.vup, c.w))
	c.v = vec3_cross(c.w, c.u)

	viewport_u := c.u * viewport_width
	viewport_v := -c.v * viewport_height

	c.pixel_delta_u = viewport_u / f64(c.image_width)
	c.pixel_delta_v = viewport_v / f64(c.image_height)

	viewport_upper_left := c.center - c.w * c.focus_dist - viewport_u / 2 - viewport_v / 2
	c.pixel00_loc = viewport_upper_left + 0.5 * (c.pixel_delta_u + c.pixel_delta_v)

	defocus_radius := c.focus_dist * math.tan(degrees_to_radians(c.defocus_angle / 2))
	c.defocus_disk_u = c.u * defocus_radius
	c.defocus_disk_v = c.v * defocus_radius

	return c
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

	ray_origin := c.center if c.defocus_angle <= 0 else defocus_disk_sample(c)
	ray_direction := pixel_sample - ray_origin
	return ray{ray_origin, ray_direction}
}

sample_square :: proc() -> vec3 {
	return vec3{random_f64() - 0.5, random_f64() - 0.5, 0}
}

defocus_disk_sample :: proc(c: camera) -> point3 {
	p := vec3_random_in_unit_disk()
	return c.center + c.defocus_disk_u * p.x + c.defocus_disk_v * p.y
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


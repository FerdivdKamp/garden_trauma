shader_type spatial;

// A compact 3D value-noise approximation of Blender's Noise -> Color Ramp.
// Ground tiles can use world coordinates so noise continues across tile edges.
// Other imported materials retain Blender-style generated coordinates.
uniform vec4 color_a : source_color;
uniform vec4 color_b : source_color;
uniform vec4 grass_color_middle : source_color;
uniform bool grass_three_color = false;
uniform float ramp_start = 0.0;
uniform float ramp_end = 1.0;
uniform float noise_scale = 3.0;
uniform float noise_detail = 2.0;
uniform float noise_roughness = 0.6;
uniform float noise_lacunarity = 2.0;
uniform float noise_distortion = 0.0;
uniform float material_roughness = 0.5;
uniform float material_metallic = 0.0;
uniform float material_specular = 0.5;
uniform vec3 generated_min = vec3(0.0);
uniform vec3 generated_size = vec3(1.0);
uniform bool use_world_space = false;
uniform float world_noise_tile_size = 2.0;
uniform bool grass_world_variation = false;
// Reduce the strong per-face lighting left by the grass mesh's small bumps.
uniform float grass_normal_flatten = 0.0;
uniform sampler2D grass_color_noise : filter_linear_mipmap, repeat_disable;
uniform float grass_world_span = 64.0;
uniform float grass_color_strength = 0.85;
// Fine color grain adds surface texture without changing the tile silhouette.
uniform float grass_detail_scale = 0.0;
uniform float grass_detail_strength = 0.0;
uniform float grass_roughness_variation = 0.0;
// The path supplies these per tile; other materials keep the effect disabled.
uniform vec4 path_shadow_sides = vec4(0.0); // north, east, south, west
uniform vec4 path_shadow_corners = vec4(0.0); // NE, SE, SW, NW
uniform vec3 path_tile_center = vec3(0.0);
uniform vec3 path_tile_axis_x = vec3(1.0, 0.0, 0.0);
uniform vec3 path_tile_axis_z = vec3(0.0, 0.0, 1.0);
uniform float path_shadow_width = 0.3;
uniform float path_shadow_strength = 0.0;
uniform float grass_edge_width = 0.5;
uniform float grass_edge_strength = 0.0;

varying vec3 noise_position;
varying vec2 grass_uv;
varying vec2 grass_world_xz;
varying vec2 path_position;

float hash3(vec3 point) {
	return fract(sin(dot(point, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float value_noise(vec3 point) {
	vec3 cell = floor(point);
	vec3 blend = fract(point);
	blend = blend * blend * (3.0 - 2.0 * blend);
	float lower = mix(
		mix(hash3(cell), hash3(cell + vec3(1.0, 0.0, 0.0)), blend.x),
		mix(hash3(cell + vec3(0.0, 1.0, 0.0)), hash3(cell + vec3(1.0, 1.0, 0.0)), blend.x),
		blend.y
	);
	float upper = mix(
		mix(hash3(cell + vec3(0.0, 0.0, 1.0)), hash3(cell + vec3(1.0, 0.0, 1.0)), blend.x),
		mix(hash3(cell + vec3(0.0, 1.0, 1.0)), hash3(cell + vec3(1.0, 1.0, 1.0)), blend.x),
		blend.y
	);
	return mix(lower, upper, blend.z);
}

void vertex() {
	vec3 path_offset = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz - path_tile_center;
	path_position = vec2(dot(path_offset, path_tile_axis_x), dot(path_offset, path_tile_axis_z));
	if (grass_world_variation && grass_normal_flatten > 0.0) {
		NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), grass_normal_flatten));
	}
	if (use_world_space) {
		vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		if (grass_world_variation) {
			// One 64 m field covers the whole 40 m Garden without repetition.
			grass_world_xz = world_position.xz;
			grass_uv = world_position.xz / grass_world_span + vec2(0.5);
		}
		noise_position = world_position / world_noise_tile_size;
	} else {
		noise_position = (VERTEX - generated_min) / max(generated_size, vec3(0.0001));
	}
}

void fragment() {
	float ramp = 0.5;
	if (grass_world_variation && grass_three_color) {
		float field = texture(grass_color_noise, grass_uv).r;
		ramp = clamp(0.5 + (field - 0.5) * grass_color_strength, 0.0, 1.0);
	} else {
		vec3 point = noise_position * noise_scale;
		if (noise_distortion != 0.0) {
			point += vec3(
				value_noise(point + vec3(17.0)),
				value_noise(point + vec3(43.0)),
				value_noise(point + vec3(71.0))
			) * noise_distortion;
		}
		float total = 0.0;
		float total_weight = 0.0;
		float frequency = 1.0;
		float amplitude = 1.0;
		for (int octave = 0; octave < 8; octave++) {
			float weight = clamp(noise_detail - float(octave), 0.0, 1.0) * amplitude;
			total += value_noise(point * frequency) * weight;
			total_weight += weight;
			frequency *= noise_lacunarity;
			amplitude *= noise_roughness;
		}
		float factor = total / max(total_weight, 0.0001);
		ramp = clamp((factor - ramp_start) / max(ramp_end - ramp_start, 0.0001), 0.0, 1.0);
	}
	vec3 grass_color = mix(color_a.rgb, color_b.rgb, ramp);
	if (grass_world_variation) {
		// Three stops let the lawn's main green change independently from its
		// deepest shadows and brightest patches. Other imported materials keep
		// their original two-stop Blender ramp.
		if (ramp < 0.5) {
			grass_color = mix(color_a.rgb, grass_color_middle.rgb, ramp * 2.0);
		} else {
			grass_color = mix(grass_color_middle.rgb, color_b.rgb, (ramp - 0.5) * 2.0);
		}
	}
	float grass_roughness = material_roughness;
	if (grass_world_variation && grass_detail_scale > 0.0) {
		// Two small scales break up the smooth color field. World coordinates
		// keep the grain aligned across rotated tiles and border pieces.
		float fine = value_noise(vec3(grass_world_xz * grass_detail_scale, 19.0));
		float grain = value_noise(vec3(grass_world_xz * grass_detail_scale * 2.4, 47.0));
		float detail = (fine * 0.7 + grain * 0.3 - 0.5) * 2.0;
		grass_color *= 1.0 + detail * grass_detail_strength;
		grass_roughness = clamp(material_roughness + detail * grass_roughness_variation, 0.0, 1.0);
	}
	// Border meshes extend well into the tile, with an irregular outline.
	// Approximate their visible edge halfway between grid edge and centre.
	// Max avoids making overlapping edges darker than a single edge.
	float width = max(path_shadow_width, 0.001);
	float lip = -0.45;
	float shadow = 0.0;
	shadow = max(shadow, path_shadow_sides.x * (1.0 - smoothstep(0.0, width, path_position.y - lip)));
	shadow = max(shadow, path_shadow_sides.y * (1.0 - smoothstep(0.0, width, -path_position.x - lip)));
	shadow = max(shadow, path_shadow_sides.z * (1.0 - smoothstep(0.0, width, -path_position.y - lip)));
	shadow = max(shadow, path_shadow_sides.w * (1.0 - smoothstep(0.0, width, path_position.x - lip)));
	shadow = max(shadow, path_shadow_corners.x * (1.0 - smoothstep(0.0, width, length(max(vec2(-path_position.x, path_position.y) - lip, vec2(0.0))))));
	shadow = max(shadow, path_shadow_corners.y * (1.0 - smoothstep(0.0, width, length(max(-path_position - lip, vec2(0.0))))));
	shadow = max(shadow, path_shadow_corners.z * (1.0 - smoothstep(0.0, width, length(max(vec2(path_position.x, -path_position.y) - lip, vec2(0.0))))));
	shadow = max(shadow, path_shadow_corners.w * (1.0 - smoothstep(0.0, width, length(max(path_position - lip, vec2(0.0))))));
	// Border meshes lie on the path tile. Shade their grass-facing lip too,
	// fading back to the normal palette before the neighboring grass tile.
	float grass_width = max(grass_edge_width, 0.001);
	float grass_edge = 0.0;
	grass_edge = max(grass_edge, path_shadow_sides.x * (1.0 - smoothstep(0.0, grass_width, abs(path_position.y + 0.45))));
	grass_edge = max(grass_edge, path_shadow_sides.y * (1.0 - smoothstep(0.0, grass_width, abs(path_position.x - 0.45))));
	grass_edge = max(grass_edge, path_shadow_sides.z * (1.0 - smoothstep(0.0, grass_width, abs(path_position.y - 0.45))));
	grass_edge = max(grass_edge, path_shadow_sides.w * (1.0 - smoothstep(0.0, grass_width, abs(path_position.x + 0.45))));
	grass_edge = max(grass_edge, path_shadow_corners.x * (1.0 - smoothstep(0.0, grass_width, distance(path_position, vec2(0.45, -0.45)))));
	grass_edge = max(grass_edge, path_shadow_corners.y * (1.0 - smoothstep(0.0, grass_width, distance(path_position, vec2(0.45, 0.45)))));
	grass_edge = max(grass_edge, path_shadow_corners.z * (1.0 - smoothstep(0.0, grass_width, distance(path_position, vec2(-0.45, 0.45)))));
	grass_edge = max(grass_edge, path_shadow_corners.w * (1.0 - smoothstep(0.0, grass_width, distance(path_position, vec2(-0.45, -0.45)))));
	ALBEDO = grass_color * (1.0 - shadow * path_shadow_strength) * (1.0 - grass_edge * grass_edge_strength);
	ROUGHNESS = grass_roughness;
	METALLIC = material_metallic;
	SPECULAR = material_specular;
}

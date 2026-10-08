shader_type spatial;

// A compact 3D value-noise approximation of Blender's Noise -> Color Ramp.
// Ground tiles can use world coordinates so noise continues across tile edges.
// Other imported materials retain Blender-style generated coordinates.
uniform vec4 color_a : source_color;
uniform vec4 color_b : source_color;
uniform float ramp_start = 0.0;
uniform float ramp_end = 1.0;
uniform float noise_scale = 3.0;
uniform float noise_detail = 2.0;
uniform float noise_roughness = 0.6;
uniform float noise_lacunarity = 2.0;
uniform float noise_distortion = 0.0;
uniform float material_roughness = 0.5;
uniform float material_metallic = 0.0;
uniform vec3 generated_min = vec3(0.0);
uniform vec3 generated_size = vec3(1.0);
uniform bool use_world_space = false;
uniform float world_noise_tile_size = 2.0;

varying vec3 noise_position;

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
	if (use_world_space) {
		noise_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz / world_noise_tile_size;
	} else {
		noise_position = (VERTEX - generated_min) / max(generated_size, vec3(0.0001));
	}
}

void fragment() {
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
	float ramp = clamp((factor - ramp_start) / max(ramp_end - ramp_start, 0.0001), 0.0, 1.0);
	ALBEDO = mix(color_a.rgb, color_b.rgb, ramp);
	ROUGHNESS = material_roughness;
	METALLIC = material_metallic;
}

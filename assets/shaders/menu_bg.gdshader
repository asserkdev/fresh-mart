shader_type canvas_item;

uniform float pulse : hint_range(0.0, 1.0) = 0.5;
uniform float time_offset : hint_range(0.0, 100.0) = 0.0;

void fragment() {
	vec2 uv = UV;
	
	// Animated gradient base
	float t = TIME * 0.3 + time_offset;
	
	// Flowing diagonal gradient
	float diag = uv.x * 0.6 + uv.y * 0.4 + sin(t * 0.5) * 0.05;
	
	// Dark green base tones
	vec3 col_a = vec3(0.03, 0.10, 0.03);   // very dark green
	vec3 col_b = vec3(0.06, 0.18, 0.06);   // dark forest
	vec3 col_c = vec3(0.02, 0.08, 0.04);   // near black green
	
	vec3 base = mix(col_a, col_b, diag);
	base = mix(base, col_c, uv.y * 0.4);
	
	// Subtle vignette
	float vignette = 1.0 - smoothstep(0.4, 1.4, length((uv - 0.5) * vec2(1.6, 1.8)));
	base *= (0.6 + vignette * 0.4);
	
	// Animated scanlines
	float scan = sin(uv.y * 180.0 + t * 2.0) * 0.012;
	base += vec3(scan * 0.3, scan, scan * 0.3);
	
	// Glowing center orb
	float orb_dist = length((uv - vec2(0.5, 0.42)) * vec2(1.8, 1.4));
	float orb = exp(-orb_dist * 4.5) * (0.08 + pulse * 0.06);
	base += vec3(orb * 0.3, orb, orb * 0.3);
	
	// Corner accent pulses
	float corner_tl = exp(-length(uv * vec2(2.5, 2.5)) * 2.0) * 0.06;
	float corner_br = exp(-length((uv - 1.0) * vec2(2.5, 2.5)) * 2.0) * 0.05;
	base += vec3(corner_tl * 0.2, corner_tl, corner_tl * 0.2);
	base += vec3(corner_br * 0.2, corner_br, corner_br * 0.2);
	
	// Horizontal glow bands
	float band1 = exp(-abs(uv.y - 0.15) * 25.0) * 0.03;
	float band2 = exp(-abs(uv.y - 0.88) * 25.0) * 0.025;
	base += vec3(band1 * 0.2, band1, band1 * 0.3);
	base += vec3(band2 * 0.1, band2, band2 * 0.2);
	
	// Moving shimmer line
	float shimmer_y = mod(t * 0.15, 1.2) - 0.1;
	float shimmer = exp(-abs(uv.y - shimmer_y) * 40.0) * 0.04;
	base += vec3(shimmer * 0.3, shimmer, shimmer * 0.4);
	
	COLOR = vec4(base, 1.0);
}

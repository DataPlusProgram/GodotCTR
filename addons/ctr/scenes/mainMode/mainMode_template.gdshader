shader_type canvas_item;

uniform vec3 BLACK = vec3(0.5);
const vec3 WHITE = vec3(1.0);

uniform float aspect_ratio = 1.3333;
uniform float squares = 2.0;
uniform float skew_x = 0.5;
uniform float skew_y = 0.0;

void fragment() {
	vec2 uv = UV;

	// Center and aspect-correct UV
	uv -= 0.5;
	uv.x *= aspect_ratio;

	// Apply flag wave motion
	float t = -TIME * 2.0 + uv.x * 7.0 + uv.y * 3.0;
	uv.y += sin(t) * 0.045;

	// Apply skew
	uv.x += uv.y * skew_x;
	uv.y += uv.x * skew_y;

	// Restore UV for checker pattern
	uv.x /= aspect_ratio;
	uv += 0.5;

	// Checker pattern
	float check = step(0.5, fract(uv.x * squares))
	            + step(0.5, fract(uv.y * squares));
	float checker = mod(check, 2.0);
	vec3 color = mix(WHITE, BLACK, checker);

	// 🌓 Sine-based shadow (darker wave sweeping across)
	float shadow_wave = sin(uv.x * 10.0 + TIME * 2.0);
	float shadow = 0.7 + 0.3 * shadow_wave; // Range ~[0.4, 1.0]
	color *= shadow;

	// Soft fade top/bottom
	color *= smoothstep(0.5, 0.49, abs(uv.y - 0.5));

	COLOR = vec4(color, 1.0);
}

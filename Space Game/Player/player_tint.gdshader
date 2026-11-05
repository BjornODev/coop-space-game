shader_type canvas_item;

// Tints only the suit: pixels that are near-white (every channel bright).
// The visor, gloves and boot soles are saturated or dark, so they keep their colours.
uniform vec4 tint : source_color = vec4(1.0);
// A pixel counts as suit when its darkest channel is at least this bright.
uniform float suit_threshold : hint_range(0.0, 1.0) = 0.75;
// Which part of the astronaut this sprite draws, so a held item can sit between them:
// 0 = everything, 1 = legs only, 2 = everything except the legs.
uniform int layer : hint_range(0, 2) = 0;

// The legs are the only light-grey (not white) and black pixels on the sheets.
bool is_leg(vec3 c) {
	bool grey = abs(c.r - c.g) < 0.03 && abs(c.g - c.b) < 0.03 && c.r > 0.6 && c.r < 0.9;
	bool sole = c.r + c.g + c.b < 0.15;
	return grey || sole;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	bool leg = is_leg(c.rgb);
	if ((layer == 1 && !leg) || (layer == 2 && leg)) {
		c.a = 0.0;
	}
	float darkest = min(c.r, min(c.g, c.b));
	if (darkest >= suit_threshold) {
		c.rgb *= tint.rgb;
	}
	COLOR = c * COLOR;
}

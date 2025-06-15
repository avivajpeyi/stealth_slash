shader_type canvas_item;

// Angle to scroll towards. In degrees. Starts at the right.
uniform float angle: hint_range(0.0, 360.0) = 45.0;
// Speed to scroll at.
uniform float speed: hint_range(-10.0, 10.0) = 1.0;

void fragment() {
	// Correct angle to start at right and convert to radians.
	float radiansAngle = radians(angle + 180.0);
	// Make a vector out of the angle.
	vec2 vector = vec2(cos(radiansAngle), sin(radiansAngle));
	// Scroll the texture.
	COLOR = texture(TEXTURE, UV + vector * speed * TIME);
}

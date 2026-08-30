shader_type canvas_item;
render_mode blend_mix;

// Cor do flash (padrao: branco puro para acertos criticos e dano padrao)
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Intensidade do flash de 0.0 (sem efeito) ate 1.0 (cor pura)
uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
	vec3 mixed_color = mix(texture_color.rgb, flash_color.rgb, flash_modifier);
	COLOR = vec4(mixed_color, texture_color.a);
}

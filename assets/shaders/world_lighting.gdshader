shader_type canvas_item;
render_mode unshaded;
uniform vec4 light_fields[12];
uniform float light_energy[12];
uniform vec3 daylight = vec3(1.0);
uniform bool detailed_lighting = true;
uniform sampler2D visibility_atlas : filter_linear, repeat_disable;
varying vec2 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	vec3 illumination = daylight;
	vec3 normal = vec3(0.0,0.0,1.0);
	float material_mask = 0.0;
	float gloss = 0.0;
	if (detailed_lighting) {
		normal = normalize(texture(NORMAL_TEXTURE,UV).rgb*2.0-1.0);
		// Default flat maps remain unchanged; only authored sloping surfaces respond.
		material_mask = smoothstep(0.025,0.10,length(normal.xy));
		gloss = texture(SPECULAR_SHININESS_TEXTURE,UV).r*material_mask;
		illumination *= 1.0+material_mask*(max(dot(normal,normalize(vec3(-0.4,-0.5,1.0))),0.0)-0.85)*0.18;
	}
	vec3 highlight = vec3(0.0);
	for (int i = 0; i < 12; i++) {
		if (light_energy[i] <= 0.0) { continue; }
		vec2 delta = (world_position-light_fields[i].xy)/max(light_fields[i].z,1.0);
		float falloff = max(0.0,1.0-dot(delta,delta));
		float visibility = 1.0;
		float response = 1.0;
		if (detailed_lighting && falloff > 0.0) {
			vec2 cell_uv = clamp(delta*0.5+0.5,vec2(0.03125),vec2(0.96875));
			visibility = texture(visibility_atlas,vec2((float(i)+cell_uv.x)/12.0,cell_uv.y)).r;
			vec3 direction = normalize(vec3(-delta,0.65));
			response = mix(1.0,0.65+0.5*max(dot(normal,direction),0.0),material_mask);
			highlight += vec3(1.0,0.75,0.42)*gloss*pow(max(dot(normal,normalize(direction+vec3(0.0,0.0,1.0))),0.0),16.0)*light_energy[i]*falloff*visibility*0.16;
		}
		illumination += vec3(0.65,0.38,0.12)*light_energy[i]*falloff*falloff*falloff*visibility*response;
	}
	COLOR.rgb = COLOR.rgb*min(illumination,vec3(1.35))+highlight*COLOR.a;
}

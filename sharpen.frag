#define KERNEL_SIZE 9

// Gaussian kernel
// 1 2 1
// 2 4 2
// 1 2 1	
//const float kernel[KERNEL_SIZE] = { 1.0/16.0, 2.0/16.0, 1.0/16.0,
//				2.0/16.0, 4.0/16.0, 2.0/16.0,
//				1.0/16.0, 2.0/16.0, 1.0/16.0 };

uniform sampler2D colorMap;

uniform float width;
uniform float height;

uniform sampler2D sampler;
uniform vec2 offset[9];
uniform int kernel[9];

//const float step_w = 1.0/width;
//const float step_h = 1.0/height;

//const vec2 offset[KERNEL_SIZE] = { vec2(-step_w, -step_h), vec2(0.0, -step_h), vec2(step_w, -step_h), 
//				vec2(-step_w, 0.0), vec2(0.0, 0.0), vec2(step_w, 0.0), 
//				vec2(-step_w, step_h), vec2(0.0, step_h), vec2(step_w, step_h) };
void main()
{
  vec4 sum = vec4(0.0);
  int i;

  for (i = 0; i < 9; i++) {
    vec4 color = texture2D(sampler, gl_TexCoord[0].st + offset[i]);
    sum += color * kernel[i];
  }

  gl_FragColor = sum;
}
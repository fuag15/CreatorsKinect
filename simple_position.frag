uniform sampler2D colorMap;

void main(void)
{
  vec4 sum = vec4(0.0);
  sum = texture2D(colorMap, gl_TexCoord[0].xy);
  //sum = vec4(1.0, 0.0, 0.0, 1.0);
  gl_FragColor = sum;
}
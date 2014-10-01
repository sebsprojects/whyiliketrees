simpleVert = "
#version 100\n
precision mediump float;

uniform mat4 mvp_matrix;

attribute vec4 vert_pos;


void main() {
  gl_Position = mvp_matrix * vert_pos;
}
"

simpleFrag = "
#version 100\n
precision mediump float;

uniform vec4 color;

void main() {
  gl_FragColor = color;
}
"

class window.ShaderProgram

  constructor: (@_vertSrc = simpleVert, @_fragSrc = simpleFrag) ->
    @_vertSrc = simpleVert
    @_fragSrc = simpleFrag
    @_vert = undefined
    @_frag = undefined
    @_program = undefined

    @_uniforms = []

  initGL: ->
    @_vert = GL.createShader GL.VERTEX_SHADER
    GL.shaderSource @_vert, @_vertSrc
    GL.compileShader @_vert
    if not GL.getShaderParameter @_vert, GL.COMPILE_STATUS
      console.log "Error in compile shader :vert: \n" +
        GL.getShaderInfoLog @_vert

    @_frag = GL.createShader GL.FRAGMENT_SHADER
    GL.shaderSource @_frag, @_fragSrc
    GL.compileShader @_frag
    if not GL.getShaderParameter @_frag, GL.COMPILE_STATUS
      console.log "Error in compile shader :frag: \n" +
        GL.getShaderInfoLog @_frag

    @_program = GL.createProgram()
    GL.attachShader @_program, @_vert
    GL.attachShader @_program, @_frag
    GL.linkProgram @_program
    if not GL.getProgramParameter @_program, GL.LINK_STATUS
      console.log "Error in link program \n" + GL.getProgramInfoLog @_program

  bindGL: ->
    GL.useProgram @_program
    for uni in @_uniforms
      uni.uniform.asUniformGL uni.location

  unbindGL: ->
    GL.useProgram null

  getAttribLocGL: (name) ->
    return GL.getAttribLocation @_program, name

  addUniformGL: (name, uniform) ->
    uni =
      uniform: uniform
      location: GL.getUniformLocation @_program, name
    @_uniforms.push uni
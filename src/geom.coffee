class window.Geom

  constructor: (@_layout) ->
    @_datasets = []

    @_vb = undefined
    @_ib = undefined

    @_stride = 0
    @_stride += s for s in @_layout

  initGL: ->
    @_vb = GL.createBuffer()
    @_ib = GL.createBuffer()
    GL.enableVertexAttribArray i for i in [0..@_layout.length-1]
    return

  drawGL: () ->
    @bindGL()
    for d in @_datasets
      continue if not d.visible
      d.program.bindGL()
      d.program.uploadUniformsGL 0
      d.program.uploadUniformsGL d.id
      GL.drawElements(GL.TRIANGLES, d.getICount(), GL.UNSIGNED_SHORT,
        d.iOffs * 2)
      d.program.unbindGL()
    @unbindGL()
    return

  uploadGL: ->
    GL.bindBuffer GL.ARRAY_BUFFER, @_vb
    GL.bufferData GL.ARRAY_BUFFER, new Float32Array(@fetchVertexData()),
      GL.STATIC_DRAW
    GL.bindBuffer GL.ARRAY_BUFFER, null

    GL.bindBuffer GL.ELEMENT_ARRAY_BUFFER, @_ib
    GL.bufferData GL.ELEMENT_ARRAY_BUFFER, new Int16Array(@fetchIndexData()),
      GL.STATIC_DRAW
    GL.bindBuffer GL.ELEMENT_ARRAY_BUFFER, null
    return

  updateGL: (id) ->
    # for now just inefficient re-upload of the whole buffer
    @uploadGL()
    return

  addData: (geomData) ->
    @_datasets.push geomData
    iOffs = 0
    for ds in @_datasets
      ds.iOffs = iOffs
      iOffs += ds.getICount()
    @uploadGL()

  fetchVertexData: ->
    vRaw = []
    for ds in @_datasets
      p.fetchVertexData vRaw for p in ds.prims
    return vRaw

  fetchIndexData: ->
    iRaw = []
    offs = 0
    for ds in @_datasets
      offs = p.fetchIndexData iRaw, offs for p in ds.prims
    return iRaw

  bindGL: ->
    GL.bindBuffer GL.ARRAY_BUFFER, @_vb
    GL.bindBuffer GL.ELEMENT_ARRAY_BUFFER, @_ib
    offs = 0
    for own index, size of @_layout
      @setAttribGL index, size, offs
      offs += size
    return

  unbindGL: ->
    GL.bindBuffer GL.ARRAY_BUFFER, null
    GL.bindBuffer GL.ELEMENT_ARRAY_BUFFER, null
    return

  setAttribGL: (i, s, offs) ->
    GL.vertexAttribPointer i, s, GL.FLOAT, false, @_stride * 4, offs * 4
    return

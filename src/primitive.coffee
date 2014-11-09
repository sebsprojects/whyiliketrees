class window.GeomData

  constructor: (@id, @program = undefined, @prims = [], @visible = true) ->
    @vOffs = 0
    @iOffs = 0

  getICount: ->
    return 0 if @prims.length is 0
    return @prims.length * @prims[0].vCount

class window.Primitive

  constructor: (@vCount) ->
    @vertices = []

  fetchVertexData: (vRaw) ->
    v.fetchVertexData vRaw for v in @vertices
    return

  fetchIndexData: (iRaw, offs) ->
    iRaw.push(i + offs) for i in [0..@vCount-1] by 1
    return offs + @vCount


class window.Vertex

  constructor: () ->
    @data = []

  fetchVertexData: (vRaw) ->
    for v in @data
      vRaw.push val for val in v.data
    return

class window.Scene

  constructor: ->
    @_lineGeom = new Geom [4, 3]
    @_lineGeom.initGL()
    @_lineShader = new ShaderProgram window.colLineVert, window.colLineFrag
    @_lineShader.initGL()
    @_lineShader.addUniformGL(0, "offs", new Vec(3, [0.0, 0.0, 0.0]))

    @_fillGeom = new Geom [4, 3, 3]
    @_fillGeom.initGL()
    @_fillShader = new ShaderProgram window.colFillVert, window.colFillFrag
    @_fillShader.initGL()
    @_fillShader.addUniformGL(0, "offs", new Vec(3, [0.0, 0.0, 0.0]))

    @_pLight1 = new PointLight(
      new Vec(3, [0.0, 30, -10.0]),
      new Vec(1, [50.0]),
      0,
      new Vec(3, [1.0, 1.0, 1.0]))
    @_pLight2 = new PointLight(
      new Vec(3, [10, 10, 0]),
      new Vec(1, [30]),
      1,
      new Vec(3, [1.0, 1.0, 1.0]))
    @_pLight1.addToProgram @_fillShader
    @_pLight2.addToProgram @_fillShader

    attenu = 0.3
    @_attenuLight = new AttenuationLight new Vec(3, [attenu, attenu, attenu])
    @_attenuLight.addToProgram @_fillShader

    window.camera.addToProgram @_lineShader
    window.camera.addToProgram @_fillShader

    @buildScene1()

    @_entities = []

  delegateDrawGL: ->
    @_lineGeom.updateGL()
    @_fillGeom.updateGL()
    @_lineGeom.drawGL()
    @_fillGeom.drawGL()
    return

  accTime = 0
  delegateDoLogic: (delta) ->
    accTime += delta

    @poly1.rotateAroundLine @pline1, Math.PI * delta * 0.0001
    @poly2.rotateAroundLine @pline1, Math.PI * delta * 0.0001

    #@ds4.setModified()
    #@ds5.setModified()
    #@ds6.setModified()
    return

  buildScene1: ->
    @color2 = new Vec 3, [1.0, 0.3, 0.3]

    @pline1 = new Line(
      new Vec(3, [0.0, 0.0, -4]),
      new Vec(3, [0.0, 0.0, 1.0]))
    @poly1 = Polygon.regularFromLine @pline1, 2, 4, -1.0

    prims = @poly1.gfxAddFill @color2
    @ds4 = new GeomData get_uid(), @_fillShader, prims, GL.TRIANGLES

    @pline2 = @pline1.shiftBaseC -5
    ndir = new Vec(3, [0.5, 0.3, 1.0])
    @pline2.setDir ndir.normalize()
    @poly2 = Polygon.regularFromLine @pline2, 2, 5
    @poly2.rotateAroundLine @pline2, Math.PI

    prims = @poly2.gfxAddFill @color2
    @ds5 = new GeomData get_uid(), @_fillShader, prims, GL.TRIANGLES

    @polys = Polygon.connectMinDist @poly1, @poly2
    #@polys = Polygon.connectPTP @poly1, @poly2
    prims = []
    prims = prims.concat p.gfxAddFill @color2 for p in @polys
    @ds6 = new GeomData get_uid(), @_fillShader, prims, GL.TRIANGLES

    lprims = []
    lprims = lprims.concat p.centroidNormalLinesDebug() for p in prims
    dds = new GeomData get_uid(), @_lineShader, lprims, GL.LINES
    @_lineGeom.addData dds

    @_fillGeom.addData @ds4
    @_fillGeom.addData @ds5
    @_fillGeom.addData @ds6

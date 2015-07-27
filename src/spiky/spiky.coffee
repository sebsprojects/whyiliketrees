class window.Spiky

  constructor: (scene) ->
    @uid = window.getuid()
    @color = new Vec 3, [0.3, 1.0, 0.3]
    @offs = new Vec 3, [-10, 0, 0]

    @initGeom()
    @initShader scene
    @initGfx scene

  initGeom: ->
    @pline1 = new Line new Vec(3, [0.0, 0.0, 0.0]), new Vec(3, [0.0, 0.0, 1.0])
    @pline2 = @pline1.shiftBaseC -5

    @poly1 = Polygon.regularFromLine @pline1, 0.75, 3, -1.0
    @poly2 = Polygon.regularFromLine @pline2, 2, 7
    @poly2.rotateAroundLine @pline2, Math.PI / 7.0
    @polys = Polygon.pConnectPolygons @poly1, @poly2
    return

  initShader: (scene) ->
    @shader = window.shaders["fillShader"]
    @shader.addUniformGL @uid, "offs", @offs
    window.camera.addToProgram @shader, @uid
    scene.attenuLight.addToProgram @shader, @uid
    scene.pLight.addToProgram @shader, @uid
    return

  initGfx: (scene) ->
    prims = []
    prims = prims.concat @poly1.gfxAddFill @color
    prims = prims.concat @poly2.gfxAddFill @color
    prims = prims.concat p.gfxAddFill @color for p in @polys

    @ds = new GeomData @uid, @shader, prims, GL.TRIANGLES
    scene.fillGeom.addData @ds
    return

  doLogic: (delta) ->
    return
class window.Polygon

  constructor: (@points, @normalSign = 1) ->
    @normal = Vec.surfaceNormal @points[0], @points[1], @points[2]
    @normal.multScalar @normalSign
    @connections = []

  gfxAddOutline: (color) ->
    n = @points.length
    verts = []
    verts.push(new Vertex([@points[i], color])) for i in [0..n-1]
    prims = []
    prims.push(new Primitive 2, [verts[i], verts[i + 1]]) for i in [0..n-2]
    prims.push(new Primitive 2, [verts[n - 1], verts[0]])
    return prims

  gfxAddFill: (color) ->
    n = @points.length
    verts = []
    verts.push(new Vertex([@points[i], color, @normal])) for i in [0..n-1]
    prims = []
    for i in [0..n-2]
      prims.push(new Primitive 3, [verts[0], verts[i], verts[i + 1]])
    return prims

  updateNormal: ->
    @normal.setTo Vec.surfaceNormal @points[0], @points[1], @points[2]
    @normal.multScalar @normalSign
    return

  rotateAroundLine: (line, angle) ->
    line.rotatePoint p, angle for p in @points
    @updateNormal()
    poly.updateNormal() for poly in conn.polys for conn in @connections
    return

  translatePoints: (dir) ->
    p.addVec dir for p in @points
    return

  getCentroid: () ->
    c = new Vec 3
    c.addVec p for p in @points
    return c.multScalar(1.0 / @points.length)

  getCentroidAxis: (length, color) ->
    return new Line @getCentroid(), @normal.copy()

  getCentroidAxisDebug: (length, color) ->
    return @getCentroidAxis().getLineSegC 0, length, color

  getOutlineC: (color = new Vec(3, [1.0, 1.0, 1.0])) ->
    col = color.copy()
    verts = []
    n = @points.length
    verts.push(new Vertex([@points[i].copy(), col])) for i in [0..n-1]
    prims = []
    prims.push(new Primitive 2, [verts[i], verts[i + 1]]) for i in [0..n-2]
    prims.push(new Primitive 2, [verts[n - 1], verts[0]])
    return prims

  # only working for convex polygons
  getFillC: (invnormal = false, color = new Vec(3, [1.0, 1.0, 1.0])) ->
    col = color.copy()
    verts = []
    n = @points.length
    normal = Vec.surfaceNormal @points[0], @points[1], @points[2]
    normal.multScalar(-1.0) if invnormal
    verts.push(new Vertex([@points[i].copy(), col, normal])) for i in [0..n-1]
    prims = []
    for i in [0..n-2]
      prims.push(new Primitive 3, [verts[0], verts[i], verts[i + 1]])
    return prims

  @regularFromLine: (line, cdist, n, normSign = 1.0) ->
    angle = 2.0 * Math.PI / n
    vecs = []
    dir = Vec.orthogonalVec(line.dir).normalize()
    for i in [0..n-1]
      vec = line.base.addVecC(dir.multScalarC cdist)
      line.rotatePoint vec, angle * i
      vec.asHom = true
      vecs.push vec
    return new Polygon vecs, normSign

  @convexFromLine: (line, cdist, angles, accumulative = true) ->
    vecs = []
    dir = Vec.orthogonalVec(line.dir).normalize()
    accum = 0
    for a in angles
      accum += a if accumulative
      accum = a if not accumulative
      vec = line.base.addVecC(dir.multScalarC cdist)
      line.rotatePoint vec, accum
      vec.asHom = true
      vecs.push vec
    return new Polygon vecs

  @getOutlineConnectionC: (poly1, poly2,
                           color = new Vec 3, [1.0, 1.0, 1.0]) ->
    col = color.copy()
    minInd = @_minDistPairIndices poly1, poly2
    n = poly1.points.length
    prims = []
    for i in [0..n-1]
      vert1 = new Vertex [poly1.points[(i + minInd[0]) %% n], col]
      vert2 = new Vertex [poly2.points[(i + minInd[1]) %% n], col]
      prims.push new Primitive 2, [vert1, vert2]
    return prims

  @getFillConnectionC: (poly1, poly2, color = new Vec 3, [1.0, 1.0, 1.0]) ->
    col = color.copy()
    minInd = @_minDistPairIndices poly1, poly2
    n = poly1.points.length
    prims = []
    for i in [0..n-1]
      vecs = [
        poly1.points[(i + minInd[0]) %% n],
        poly2.points[(i + minInd[1]) %% n],
        poly1.points[(i + 1 + minInd[0]) %% n],
        poly2.points[(i + 1 + minInd[1]) %% n]
      ]
      normal1 = Vec.surfaceNormal vecs[2], vecs[1], vecs[0]
      normal2 = Vec.surfaceNormal vecs[1], vecs[2], vecs[3]
      verts1 = []
      verts2 = []
      verts1.push new Vertex [vecs[i], col, normal1] for i in [0..2]
      verts2.push new Vertex [vecs[i], col, normal2] for i in [1..3]
      prims.push new Primitive 3, verts1
      prims.push new Primitive 3, verts2
    return prims

  # minimum distance match points
  @pointConnect: (p1, p2) ->
    normSign = 1.0
    if p1.points.length <= p2.points.length
      poly1 = p1 # poly1 = smaller n = inner
      poly2 = p2 # poly2 = bigger n = outer
    else
      poly1 = p2
      poly2 = p1
      normSign = -1.0
    p1s = poly1.points
    p2s = poly2.points
    #move them on top of each other
    p2sm = Polygon._matchPositioning(poly1, poly2).points
    polys = []
    outers = []
    outers.push [] for i in [0..p1s.length-1]
    for i in [0..p1s.length-1]
      # inner partitions outer in outers[inner] = [lowerInd, upperInd]
      fsti = i
      sndi = (i + 1) %% p1s.length
      cornerInd = Polygon._minDistToPair p1s, p2sm, fsti, sndi
      outers[fsti].push cornerInd
      outers[sndi].push cornerInd
      polys.push new Polygon [p1s[fsti], p1s[sndi], p2s[cornerInd]], normSign
    # switch only first
    k = outers[0][0]
    outers[0][0] = outers[0][1]
    outers[0][1] = k
    for i in [0..p1s.length-1]
      bases = Polygon._getBases outers, i, p2s.length
      continue if bases.length == 0 # needed if n = n
      for j in [0..bases.length-2]
        poly = new Polygon [p2s[bases[j]], p2s[bases[j+1]], p1s[i]], -normSign
        polys.push poly
    conn1 =
      connection: poly2
      polys: polys
    conn2 =
      connection: poly1
      polys: polys
    poly1.connections.push conn1
    poly2.connections.push conn2
    return polys

  @_getBases: (outers, i, n) ->
    span = outers[i]
    result = []
    dist = (span[1] + n - span[0]) %% n
    return [] if dist == 0
    for i in [0..dist]
      result.push (span[0] + i) %% n
    return result

  @_minDistPairIndices: (poly1, poly2) ->
    n = poly1.points.length
    m = poly2.points.length
    mindist = 1000000
    minInd1 = undefined
    minInd2 = undefined
    for i in [0..n-1]
      for j in [0..m-1]
        if mindist > (d = poly1.points[i].distance(poly2.points[j]))
          mindist = d
          minInd1 = i
          minInd2 = j
    return [minInd1, minInd2]

  @_minDistToPair: (base, corner, ind1, ind2) ->
    minInd = undefined
    mindist = 1000000
    for i in [0..corner.length-1]
      dist = base[ind1].distance(corner[i])
      dist += base[ind2].distance(corner[i])
      if mindist > dist
        mindist = dist
        minInd = i
    return minInd

  @_matchPositioning: (poly1, poly2) ->
    newpoints = []
    newpoints.push p.copy() for p in poly2.points
    newPoly = new Polygon newpoints, poly2.normalSign
    centDiff = poly1.getCentroid().subVec newPoly.getCentroid()
    newPoly.translatePoints centDiff

    if isFloatZero(Math.abs(Vec.scalarProd(poly1.normal, newPoly.normal)) - 1)
      return newPoly
    axis = Vec.crossProd3(poly1.normal, newPoly.normal).normalize()
    rline = new Line newPoly.getCentroid(), axis
    rangle = Math.acos(
      Vec.scalarProd poly1.normal, newPoly.normal.multScalarC(-1.0))
    newPoly.rotateAroundLine rline, rangle
    return newPoly

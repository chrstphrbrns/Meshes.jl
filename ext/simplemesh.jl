# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

Makie.plottype(::SimpleMesh) = Viz{<:Tuple{SimpleMesh}}

function Makie.plot!(plot::Viz{<:Tuple{SimpleMesh}})
  # retrieve mesh and rank
  mesh = plot[:object][]
  rank = paramdim(mesh)

  # different recipes for meshes with
  # 1D, 2D, 3D, ... ND simplices
  if rank == 1
    # visualize segments
    vizmesh1D!(plot)
  elseif rank == 2
    # visualize polygons
    vizmesh2D!(plot)
  elseif rank == 3
    # visualize polyhedra
    vizmesh3D!(plot)
  end
end

function vizmesh1D!(plot)
  mesh = plot[:object]
  color = plot[:color]
  alpha = plot[:alpha]
  colorscheme = plot[:colorscheme]
  segmentsize = plot[:segmentsize]

  # process color spec into colorant
  colorant = Makie.@lift process($color, $colorscheme, $alpha)

  # retrieve coordinates of segments
  coords = Makie.@lift let
    topo = topology($mesh)
    vert = vertices($mesh)
    segmentsof(topo, vert)
  end

  # repeat colors for vertices of segments
  colors = Makie.@lift let
    if $colorant isa AbstractVector
      c = [$colorant[e] for e in 1:nelements($mesh) for _ in 1:3]
      c[begin:(end - 1)]
    else
      $colorant
    end
  end

  # visualize segments
  Makie.lines!(plot, coords, color=colors, linewidth=segmentsize)
end

function vizmesh2D!(plot)
  mesh = plot[:object]
  color = plot[:color]
  alpha = plot[:alpha]
  colorscheme = plot[:colorscheme]
  facetcolor = plot[:facetcolor]
  showfacets = plot[:showfacets]
  segmentsize = plot[:segmentsize]

  # process color spec into colorant
  colorant = Makie.@lift process($color, $colorscheme, $alpha)

  # retrieve triangle mesh parameters
  tparams = Makie.@lift let
    # relevant settings
    dim = embeddim($mesh)
    nvert = nvertices($mesh)
    nelem = nelements($mesh)
    verts = vertices($mesh)
    topo = topology($mesh)
    elems = elements(topo)

    # coordinates of vertices
    coords = coordinates.(verts)

    # fan triangulation (assume convexity)
    tris4elem = map(elems) do elem
      I = indices(elem)
      [[I[1], I[i], I[i + 1]] for i in 2:(length(I) - 1)]
    end

    # flatten vector of triangles
    tris = [tri for tris in tris4elem for tri in tris]

    # element vs. vertex coloring
    if $colorant isa AbstractVector
      ncolor = length($colorant)
      if ncolor == nelem # element coloring
        # duplicate vertices and adjust
        # connectivities to avoid linear
        # interpolation of colors
        nt = 0
        elem4tri = Dict{Int,Int}()
        for e in 1:nelem
          Δs = tris4elem[e]
          for _ in 1:length(Δs)
            nt += 1
            elem4tri[nt] = e
          end
        end
        nv = 3nt
        tcoords = [coords[i] for tri in tris for i in tri]
        tconnec = [collect(I) for I in Iterators.partition(1:nv, 3)]
        tcolors = map(1:nv) do i
          t = ceil(Int, i / 3)
          e = elem4tri[t]
          $colorant[e]
        end
      elseif ncolor == nvert # vertex coloring
        # nothing needs to be done because
        # this is the default in Makie and
        # because the triangulation above
        # does not change the vertices in
        # the original polygonal mesh
        tcoords = coords
        tconnec = tris
        tcolors = $colorant
      else
        throw(ArgumentError("Provided $ncolor colors but the mesh has
                            $nvert vertices and $nelem elements."))
      end
    else # single color
      # nothing needs to be done
      tcoords = coords
      tconnec = tris
      tcolors = $colorant
    end

    # convert connectivities to matrix format
    tmatrix = reduce(hcat, tconnec) |> transpose

    # enable shading in 3D
    tshading = dim == 3

    tcoords, tmatrix, tcolors, tshading
  end

  # unpack observable of parameters
  tcoords = Makie.@lift $tparams[1]
  tmatrix = Makie.@lift $tparams[2]
  tcolors = Makie.@lift $tparams[3]
  tshading = Makie.@lift $tparams[4]

  Makie.mesh!(plot, tcoords, tmatrix, color=tcolors, shading=tshading)

  if showfacets[]
    # retrieve coordinates parameters
    xparams = Makie.@lift let
      # relevant settings
      dim = embeddim($mesh)
      topo = topology($mesh)
      nvert = nvertices($mesh)
      verts = vertices($mesh)
      coords = coordinates.(verts)

      # use a sophisticated data structure
      # to extract the edges from the n-gons
      t = convert(HalfEdgeTopology, topo)
      ∂ = Boundary{1,0}(t)

      # append indices of incident vertices
      # interleaved with a sentinel index
      inds = Int[]
      for i in 1:nfacets(t)
        append!(inds, ∂(i))
        push!(inds, nvert + 1)
      end

      # fill sentinel index with NaN coordinates
      push!(coords, Vec(ntuple(i -> NaN, dim)))

      # extract incident vertices
      coords = coords[inds]

      # split coordinates to match signature
      [getindex.(coords, j) for j in 1:dim]
    end

    # unpack observable of paramaters
    xyz = map(1:embeddim(mesh[])) do i
      Makie.@lift $xparams[i]
    end

    Makie.lines!(plot, xyz..., color=facetcolor, linewidth=segmentsize)
  end
end

function vizmesh3D!(plot)
  mesh = plot[:object]
  meshes = Makie.@lift let
    geoms = elements($mesh)
    bounds = boundary.(geoms)
    discretize.(bounds)
  end
  vizmany!(plot, meshes)
end

function segmentsof(topo, vert)
  dim = embeddim(first(vert))
  nan = Vec(ntuple(i -> NaN, dim))
  xs = coordinates.(vert)

  coords = map(elements(topo)) do e
    inds = indices(e)
    xs[collect(inds)]
  end

  reduce((x, y) -> [x; [nan]; y], coords)
end

function segmentsof(topo::GridTopology, vert)
  xs = coordinates.(vert)
  ip = first(isperiodic(topo))
  ip ? [xs; [first(xs)]] : xs
end

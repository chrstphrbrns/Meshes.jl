# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    pointify(object)

Convert `object` into a vector of [`Point`](@ref)
by sampling its boundary.
"""
function pointify end

# ----------
# FALLBACKS
# ----------

pointify(p::Primitive) = pointify(boundary(p))

pointify(p::Polytope) = collect(vertices(p))

pointify(m::Multi) = pointify(collect(m))

pointify(geoms) = mapreduce(pointify, vcat, geoms)

# ----------------
# SPECIALIZATIONS
# ----------------

pointify(p::Point) = [p]

pointify(s::Sphere) = _rsample(s)

pointify(t::Torus) = _rsample(t)

pointify(p::PolyArea) = vertices(p)

pointify(r::Ring) = vertices(r)

pointify(r::Rope) = vertices(r)

pointify(p::PointSet) = collect(p)

pointify(m::Mesh) = vertices(m)

# ----------------
# IMPLEMENTATIONS
# ----------------

_rsample(g::Geometry) = collect(sample(g, RegularSampling(50)))

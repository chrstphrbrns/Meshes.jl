# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    Geometry{Dim,T}

A geometry embedded in a `Dim`-dimensional space with coordinates of type `T`.
"""
abstract type Geometry{Dim,T} end

Broadcast.broadcastable(g::Geometry) = Ref(g)

"""
    embeddim(geometry)

Return the number of dimensions of the space where the `geometry` is embedded.
"""
embeddim(::Type{<:Geometry{Dim,T}}) where {Dim,T} = Dim
embeddim(g::Geometry) = embeddim(typeof(g))

"""
    paramdim(geometry)

Return the number of parametric dimensions of the `geometry`. For example, a
sphere embedded in 3D has 2 parametric dimensions (polar and azimuthal angles).

See also [`isparametrized`](@ref).
"""
paramdim(g::Geometry) = paramdim(typeof(g))

"""
    coordtype(geometry)

Return the machine type of each coordinate used to describe the `geometry`.
"""
coordtype(::Type{<:Geometry{Dim,T}}) where {Dim,T} = T
coordtype(g::Geometry) = coordtype(typeof(g))

"""
    centroid(geometry)

Return the centroid of the `geometry`.
"""
centroid(g::Geometry) = center(g)

"""
    measure(geometry)

Return the measure of the `geometry`, i.e. the length, area, or volume.
"""
measure(g::Geometry) = sum(measure, discretize(g))

"""
    perimeter(geometry)

Return the perimeter of the `geometry`, i.e. the measure of its boundary.
"""
perimeter(g::Geometry) = measure(boundary(g))

"""
    extrema(geometry)

Return the top left and bottom right corners of the
bounding box of the `geometry`.
"""
Base.extrema(g::Geometry) = extrema(boundingbox(g))

"""
    boundary(geometry)

Return the boundary of the `geometry`.
"""
function boundary end

# ----------------
# IMPLEMENTATIONS
# ----------------

include("primitives.jl")
include("polytopes.jl")
include("multigeoms.jl")

# ------------
# CONVERSIONS
# ------------

Base.convert(::Type{<:Quadrangle}, b::Box{2}) = Quadrangle(vertices(boundary(b))...)

Base.convert(::Type{<:Hexahedron}, b::Box{3}) = Hexahedron(vertices(boundary(b))...)

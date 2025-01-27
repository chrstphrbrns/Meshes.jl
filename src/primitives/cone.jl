# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

"""
    Cone(disk, apex)

A cone with base `disk` and `apex`.
See https://en.wikipedia.org/wiki/Cone.

See also [`ConeSurface`](@ref).
"""
struct Cone{T} <: Primitive{3,T}
  disk::Disk{T}
  apex::Point{3,T}
end

Cone(disk::Disk, apex::Tuple) = Cone(disk, Point(apex))

paramdim(::Type{<:Cone}) = 3

boundary(c::Cone) = ConeSurface(c.disk, c.apex)

Random.rand(rng::Random.AbstractRNG, ::Random.SamplerType{Cone{T}}) where {T} =
  Cone(rand(rng, Disk{T}), rand(rng, Point{3,T}))

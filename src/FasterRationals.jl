module FasterRationals

export FastRational

# traits

"""
    RationalTrait

a trait applicable to Rational values
"""
abstract type RationalTrait end

"""
    IsReduced <: RationalTrait

This trait holds for rational values that are known to have been reduced to lowest terms.
"""
struct IsReduced  <: RationalTrait end
const QIsReduced = IsReduced()

"""
    Reduceable <: RationalTrait

This trait holds for rational values that are known not to be expressed in lowest terms.
"""
struct Reduceable <: RationalTrait end
const QReduceable = Reduceable()

"""
    MayReduced <: RationalTrait

This trait holds for rational values that may or may not be expressed in lowest terms.
"""
struct MayReduce  <: RationalTrait end
const QMayReduce = MayReduce()

struct TraitedRational{T, H<:RationalTrait}
    num::T
    den::T
    trait::H
end

eltype(x::TraitedRational{T,H}) = T
trait(x::TraitedRational{T,H}) = t.trait

IsReduced(x::TraitedRational{T,H}) where {T,H} = x.trait === QIsReduced
Reducable(x::TraitedRational{T,H}) where {T,H} = x.trait === QReducable
MayReduce(x::TraitedRational{T,H}) where {T,H} = x.trait === QMayReduce

TraitedRational(x::Rational{T}) where {T} = TraitedRational(x.num, x.den, QIsReduced)
Rational(x::TraitedRational{T,H}) where {T,H} = Rational{T}(x.num, x.den)

canonical(x::TraitedRational{T,H}) where {T, H<:IsReduced} = x

function canonical(x::TraitedRational{T,H}) =
    n, d = canonical(x.num, x.den)
    return TraitedRational{T, IsReduced}(n, d, QIsReduced)
end
    

struct FasterRational{T, H<:RationalTrait}
    num::T
    den::T
end

eltype(x::FasterRational{T,H}) = T
trait(x::FasterRational{T,H}) = H

IsReduced(x::FasterRational{T,H}) where {T,H} = H === IsReduced
Reducable(x::FasterRational{T,H}) where {T,H} = H === Reducable
MayReduce(x::FasterRational{T,H}) where {T,H} = H === MayReduce

FasterRational(x::Rational{T}) where {T} = FasterRational{T,IsReduced}(x.num, x.den)
Rational(x::FasterRational{T,H}) where {T,H} = Rational{T}(x.num, x.den)


canonical(x::FasterRational{T,H}) where {T, H<:IsReduced} = x

function canonical(x::FasterRational{T,H}) =
    n, d = canonical(x.num, x.den)
    return FasterRational{T, IsReduced}(n, d)
end



"""
    canonical(numerator::T, denominator::T) where T<:Signed

Rational numbers that are finite and normatively bounded by
the extremal magnitude of an underlying signed type have a
canonical representation.
- numerator and denominator have no common factors
- numerator may be negative, zero or positive
- denominator is strictly positive (d > 0)
""" canonical

function canonical(num::T, den::T) where {T<:SignedInt}
    num, den = canonical_signed(num, den)
    num, den = canonical_valued(num, den)
    return num, den
end

@inline function canonical_signed(num::T, den::T) where {T<:SignedInt}
    return flipsign(num, den), abs(den)
end

@inline function canonical_valued(num::T, den::T) where {T<:SignedInt}
    gcdval = gcd(num, den)
    gcdval === one(T) && return num, den
    num = div(num, gcdval)
    den = div(den, gcdval)
    return num, den
end
    
    
    
    
    
    
    
    
    
    

struct ReducedRational{T<:Signed}
    num::T
    den::T
end

struct ReducibleRational{T<:Signed}
    num::T
    den::T
end

struct UnreducedRational{T<:Signed}
    num::T
    den::T
end


       ReduceRawRational

import Base: convert, promote_rule, string, show,
    isfinite, isinteger,
    signbit, flipsign, changesign,
    (+), (-), (*), (//), div, rem, fld, mod, cld,
    (==), (<), (<=), isequal, isless

import Base.Checked: add_with_overflow, sub_with_overflow, mul_with_overflow

const SignedInt = Union{Int16, Int32, Int64, Int128, BigInt}


include(joinpath(".", "types", "namedtuple", "fast_rational.jl"))
    
include(joinpath(".", "types","shared.jl"))

include(joinpath("types", "namedtuple", "fast_rational.jl"))
include(joinpath("types", "struct",     "fast_rational.jl"))
include(joinpath("types", "mutable",    "fast_rational.jl"))

include(joinpath("int_ops", "namedtuple", "fast_rational.jl"))
include(joinpath("int_ops", "struct",     "fast_rational.jl"))
include(joinpath("int_ops", "mutable",    "fast_rational.jl"))

include(joinpath("types", "namedtuple", "compares.jl"))
include(joinpath("types", "struct",     "compares.jl"))
include(joinpath("types", "mutable",    "compares.jl"))

end # FasterRationals

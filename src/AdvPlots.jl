\
module AdvPlots
export hist2d

using CairoMakie
using StatsBase
using LaTeXStrings
using MathTeXEngine

include(joinpath(@__DIR__, "..", "Helpers", "Helpers.jl"))
include(joinpath(@__DIR__, "..", "test", "impl", "hist2d.jl"))

end # module

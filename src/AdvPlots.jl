module AdvPlots

export hist2d,
       semicircular_hist,
       folded_pdf,
       phase_diagram,
       quiver_field_makie,
       quiver_slice_from_cubes

using CairoMakie
using StatsBase
using LaTeXStrings
using MathTeXEngine
using Statistics
import Makie

include("helpers.jl")
include("hist2d.jl")
include("AngleHistogram.jl")
include("anglePDF.jl")
include("figurePhaseDiag.jl")
include("QuiverSliceDemo.jl")
using .QuiverSliceDemo: quiver_field_makie, quiver_slice_from_cubes

end # module

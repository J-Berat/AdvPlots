# deps.jl — add runtime dependencies and (re)generate Manifest.toml
import Pkg
Pkg.activate(@__DIR__)
Pkg.add([
    "CairoMakie",
    "StatsBase",
    "LaTeXStrings",
    "MathTeXEngine",
    "Distributions",
    "Statistics",
])
Pkg.resolve()
Pkg.precompile()
println("✅ Dependencies installed. You can now `using AdvPlots`.")

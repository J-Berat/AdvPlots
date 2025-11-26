# deps.jl — add runtime dependencies and (re)generate Manifest.toml
import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()
Pkg.precompile()
println("✅ Dependencies installed. You can now `using AdvPlots`.")

module QuiverSliceDemo

using Statistics
import Makie
using LaTeXStrings

#-------------- helpers --------------
@inline _L(s) = s isa LaTeXString ? s : LaTeXString(String(s))

_format_one(x::Real; low=1e-3, high=1e4) = begin
    xv = float(x)
    if xv == 0.0 || (abs(xv) ≥ low && abs(xv) < high)
        _L(string(round(xv, sigdigits=4)))
    else
        k  = floor(Int, log10(abs(xv)))
        c  = xv / (10.0^k)
        _L(string(round(c, sigdigits=3)) * "\\times 10^{" * string(k) * "}")
    end
end

function _latex_tickformat(; low::Float64=1e-3, high::Float64=1e4)
    return val -> (val isa AbstractVector ? map(x -> _format_one(x; low=low, high=high), val)
                                         : _format_one(val; low=low, high=high))
end

_fix_clims(cr::Tuple{<:Real,<:Real}) = cr[1] == cr[2] ? ((δ = max(abs(cr[1])*1e-6, 1e-9)); (cr[1]-δ, cr[2]+δ)) : cr

function _auto_lengthscale(x::Vector{Float64}, y::Vector{Float64},
                           u::Vector{Float64}, v::Vector{Float64};
                           target_fraction::Float64 = 0.6)
    mags = hypot.(u, v); mags = mags[mags .> 0]
    isempty(mags) && return 0.1
    meddiff(vec) = (length(vec) < 2 ? NaN :
                    (let vs = sort(unique(vec)); length(vs) >= 2 ? Statistics.median(diff(vs)) : NaN end))
    dx, dy = meddiff(x), meddiff(y)
    d = (isfinite(dx) && dx>0 && isfinite(dy) && dy>0) ? min(dx,dy) : begin
        rx = maximum(x)-minimum(x); ry = maximum(y)-minimum(y)
        approxn = max(10, round(Int, sqrt(length(x))))
        v = min(rx, ry) / approxn
        v > 0 ? v : 0.1
    end
    m = Statistics.median(mags)
    return target_fraction * d / m
end

function activate_backend!(backend::Symbol = :auto)::Symbol
    if backend === :gl || backend === :auto
        try
            @eval using GLMakie
            GLMakie.activate!(); return :gl
        catch
            backend === :gl && @warn "GLMakie not available, falling back to CairoMakie"
        end
    end
    @eval begin
        using CairoMakie
        CairoMakie.activate!()
    end
    return :cairo
end

#-------------- API --------------
function quiver_field_makie(x::AbstractVector, y::AbstractVector,
                            u::AbstractVector, v::AbstractVector;
                            xlabel::AbstractString="x",
                            ylabel::AbstractString="y",
                            color=nothing,
                            colormap=:viridis,
                            clims::Union{Nothing,Tuple{Real,Real}}=nothing,
                            tipwidth::Real=8,
                            tiplength::Real=12,
                            shaftwidth::Real=2.0,
                            normalize::Bool=false,
                            lengthscale::Union{Real,Symbol}=:auto,
                            backend::Symbol=:auto,
                            showfig::Bool=true,
                            outfile::Union{Nothing,AbstractString}="quiver.png",
                            figsize::Tuple{Int,Int}=(900, 700),
                            colorbarlabel::AbstractString="color",
                            colorbarwidth::Real=20)

    backend_used = activate_backend!(backend)

    n = length(x)
    n == length(y) == length(u) == length(v) || throw(ArgumentError("x, y, u, v must have same length"))
    n > 0 || throw(ArgumentError("empty inputs"))

    mask = .!ismissing.(x) .& .!ismissing.(y) .& .!ismissing.(u) .& .!ismissing.(v)
    xv, yv = Float64.(x[mask]), Float64.(y[mask])
    uv, vv = Float64.(u[mask]), Float64.(v[mask])
    fin = isfinite.(xv) .& isfinite.(yv) .& isfinite.(uv) .& isfinite.(vv)
    xv, yv, uv, vv = xv[fin], yv[fin], uv[fin], vv[fin]
    isempty(xv) && throw(ArgumentError("no valid data after cleaning"))

    colorvec = if color === nothing
        hypot.(uv, vv)
    elseif isa(color, AbstractVector)
        cv = Float64.(color[mask])[fin]
        length(cv) == length(uv) || throw(ArgumentError("color length mismatch after cleaning"))
        cv
    else
        Float64.(fill(color, length(uv)))
    end

    cr = clims === nothing ? extrema(colorvec) : Tuple(clims)
    cr = _fix_clims(cr)

    ls = lengthscale === :auto ? _auto_lengthscale(xv, yv, uv, vv) :
         (lengthscale isa Real ? Float64(lengthscale) :
          throw(ArgumentError("lengthscale must be a Real or :auto")))
    ls <= 0 && (ls = 0.1)

    # Always LaTeX
    x_lbl  = _L(xlabel)
    y_lbl  = _L(ylabel)
    cb_lbl = _L(colorbarlabel)
    tickfmt = _latex_tickformat()

    pts  = Makie.Point2f.(xv, yv)
    vecs = Makie.Vec2f.(uv, vv)

    fig = Makie.Figure(size = figsize)
    ax  = Makie.Axis(fig[1, 1]; xlabel=x_lbl, ylabel=y_lbl, title = L"", aspect=Makie.DataAspect())
    ax.titlevisible[] = false
    ax.xtickformat[] = tickfmt
    ax.ytickformat[] = tickfmt
    ax.xgridvisible[] = false
    ax.ygridvisible[] = false
                plt = Makie.arrows2d!(ax, pts, vecs;
        color       = colorvec,
        colormap    = colormap,
        colorrange  = cr,
        tipwidth    = tipwidth,
        tiplength   = tiplength,
        shaftwidth  = shaftwidth,
        normalize   = normalize,
        lengthscale = ls,
    )
    cbar = Makie.Colorbar(fig[1, 2], plt; label = cb_lbl, width = colorbarwidth)
    cbar.tickformat[] = tickfmt

    showfig && display(fig)
    if outfile !== nothing
        Makie.save(outfile, fig)
        println("✅ saved: ", abspath(outfile))
    end

    return (; fig, ax, plt, lengthscale = ls, backend = backend_used)
end

function quiver_slice_from_cubes(Bx::AbstractArray{<:Real,3},
                                 By::AbstractArray{<:Real,3},
                                 Bz::AbstractArray{<:Real,3},
                                 x::AbstractVector, y::AbstractVector, z::AbstractVector;
                                 axis::Symbol=:z,
                                 index::Union{Nothing,Int}=nothing,
                                 coord::Union{Nothing,Real}=nothing,
                                 every::Int=1,
                                 colorby::Symbol=:mag,
                                 colormap=:viridis,
                                 clims::Union{Nothing,Tuple{Real,Real}}=nothing,
                                 tipwidth::Real=8,
                                 tiplength::Real=12,
                                 shaftwidth::Real=2.0,
                                 normalize::Bool=false,
                                 lengthscale::Union{Real,Symbol}=:auto,
                                 backend::Symbol=:auto,
                                 showfig::Bool=true,
                                 outfile::Union{Nothing,AbstractString}="quiver.png",
                                 savedir::Union{Nothing,AbstractString}=nothing,
                                 figsize::Tuple{Int,Int}=(900,700),
                                 colorbarwidth::Real=20)

    size(Bx) == size(By) == size(Bz) || throw(ArgumentError("Bx, By, Bz must match"))
    Nx, Ny, Nz = size(Bx)
    length(x) == Nx && length(y) == Ny && length(z) == Nz || throw(ArgumentError("x/y/z sizes mismatch"))
    every ≥ 1 || throw(ArgumentError("every ≥ 1"))

    idx = index !== nothing ? index :
          coord !== nothing ? (axis === :x ? argmin(abs.(x .- coord)) :
                               axis === :y ? argmin(abs.(y .- coord)) :
                               axis === :z ? argmin(abs.(z .- coord)) :
                               throw(ArgumentError("axis must be :x|:y|:z"))) :
          throw(ArgumentError("provide `index` or `coord`"))

    if axis === :z
        1 ≤ idx ≤ Nz || throw(ArgumentError("index out of bounds for z"))
        I = 1:every:Nx; J = 1:every:Ny
        xv = Float64[]; yv = Float64[]; uv = Float64[]; vv = Float64[]; wv = Float64[]
        for j in J, i in I
            push!(xv, x[i]); push!(yv, y[j])
            push!(uv, Bx[i,j,idx]); push!(vv, By[i,j,idx]); push!(wv, Bz[i,j,idx])
        end
        xlabel, ylabel = L"x", L"y"
    elseif axis === :x
        1 ≤ idx ≤ Nx || throw(ArgumentError("index out of bounds for x"))
        J = 1:every:Ny; K = 1:every:Nz
        xv = Float64[]; yv = Float64[]; uv = Float64[]; vv = Float64[]; wv = Float64[]
        for k in K, j in J
            push!(xv, y[j]); push!(yv, z[k])
            push!(uv, By[idx,j,k]); push!(vv, Bz[idx,j,k]); push!(wv, Bx[idx,j,k])
        end
        xlabel, ylabel = L"y", L"z"
    elseif axis === :y
        1 ≤ idx ≤ Ny || throw(ArgumentError("index out of bounds for y"))
        I = 1:every:Nx; K = 1:every:Nz
        xv = Float64[]; yv = Float64[]; uv = Float64[]; vv = Float64[]; wv = Float64[]
        for k in K, i in I
            push!(xv, x[i]); push!(yv, z[k])
            push!(uv, Bx[i,idx,k]); push!(vv, Bz[i,idx,k]); push!(wv, By[i,idx,k])
        end
        xlabel, ylabel = L"x", L"z"
    else
        throw(ArgumentError("axis must be :x, :y or :z"))
    end

    colorvec = colorby === :mag    ? hypot.(uv, vv) :
               colorby === :w      ? wv :
               colorby === :norm3d ? sqrt.(uv .^ 2 .+ vv .^ 2 .+ wv .^ 2) :
               throw(ArgumentError("colorby must be :mag, :w, or :norm3d"))

    outpath = outfile === nothing ? nothing :
              savedir === nothing ? outfile : joinpath(savedir, outfile)

    return quiver_field_makie(xv, yv, uv, vv;
        xlabel       = xlabel,
        ylabel       = ylabel,
        color        = colorvec,
        colormap     = colormap,
        clims        = clims,
        tipwidth     = tipwidth,
        tiplength    = tiplength,
        shaftwidth   = shaftwidth,
        normalize    = normalize,
        lengthscale  = lengthscale,
        backend      = backend,
        showfig      = showfig,
        outfile      = outpath,
        figsize      = figsize,
        colorbarlabel= "color",
        colorbarwidth= colorbarwidth,
    )
end

end # module

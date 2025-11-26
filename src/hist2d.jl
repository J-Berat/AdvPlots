# Plotting implementation included into AdvPlots module.

function hist2d(x::AbstractVector, y::AbstractVector;
                xname::AbstractString="var1", yname::AbstractString="var2",
                nbins::Tuple{Int,Int}=(40,40),
                xrange::Union{Nothing,Tuple{Real,Real}}=nothing,
                yrange::Union{Nothing,Tuple{Real,Real}}=nothing,
                norm::Symbol=:none,
                scale::Symbol=:linear,
                colormap=:viridis,
                clims::Union{Nothing,Tuple{Real,Real}}=nothing,
                outdir::Union{Nothing,AbstractString}=nothing,
                outfile::Union{Nothing,AbstractString}=nothing,
                size::Tuple{Int,Int}=(900,700))

    length(x) == length(y) || throw(ArgumentError("x and y must have the same length"))
    all(>(0), nbins) || throw(ArgumentError("nbins must be > 0"))
    norm  in (:none, :probability, :pdf) || throw(ArgumentError("invalid norm"))
    scale in (:linear, :log10)          || throw(ArgumentError("invalid scale"))

    # Clean
    mask = .!ismissing.(x) .& .!ismissing.(y)
    xv, yv = Float64.(x[mask]), Float64.(y[mask])
    fin = isfinite.(xv) .& isfinite.(yv)
    xv, yv = xv[fin], yv[fin]
    isempty(xv) && throw(ArgumentError("no valid data"))

    # Ranges
    xr = isnothing(xrange) ? (minimum(xv), maximum(xv)) : Tuple(xrange)
    yr = isnothing(yrange) ? (minimum(yv), maximum(yv)) : Tuple(yrange)
    xr[1] < xr[2] || throw(ArgumentError("invalid xrange"))
    yr[1] < yr[2] || throw(ArgumentError("invalid yrange"))

    # Histogram
    xedges = collect(range(xr[1], xr[2], length=nbins[1]+1))
    yedges = collect(range(yr[1], yr[2], length=nbins[2]+1))
    h = StatsBase.fit(Histogram, (xv, yv), (xedges, yedges))
    w = Float64.(h.weights)

    # Normalization
    if norm == :probability
        s = sum(w)
        s > 0 && (w ./= s)
    elseif norm == :pdf
        s = sum(w)
        if s > 0
            area = (xedges[2]-xedges[1]) * (yedges[2]-yedges[1])
            area <= 0 && throw(ArgumentError("zero bin area"))
            w ./= (s * area)
        end
    end

    # Color scale
    if scale == :log10
        minpos = minimum(w[w .> 0]; init=Inf)
        eps = isfinite(minpos) ? minpos * 1e-3 : 1e-12
        wplot = log10.(w .+ eps)
        cr = isnothing(clims) ? extrema(wplot) :
             (all(>(0), clims) ? (log10(clims[1]), log10(clims[2])) :
              throw(ArgumentError("clims must be > 0 for :log10")))
        cr = _safe_clims(cr)
        cbar_ticks = _ticks_log10(cr)
        cbar_label = LaTeXStrings.latexstring("\\mathrm{count}\\;\\text{or}\\;\\mathrm{density}\\;(\\log_{10})")
    else
        wplot = w
        cr = _safe_clims(isnothing(clims) ? extrema(w) : Tuple(clims))
        cbar_ticks = _ticks_lin(cr...)
        cbar_label = LaTeXStrings.latexstring("\\mathrm{count}\\;\\mathrm{density}")
    end

    # Centers + axis ticks (LaTeX)
    xcenters = @. (xedges[1:end-1] + xedges[2:end]) / 2
    ycenters = @. (yedges[1:end-1] + yedges[2:end]) / 2
    xticks = _ticks_lin(xr[1], xr[2])
    yticks = _ticks_lin(yr[1], yr[2])

    # Labels (LaTeX), no title
    xlab = _latex_var(xname)
    ylab = _latex_var(yname)

    fig = Figure(size = size)
    ax  = Axis(fig[1, 1]; xlabel=xlab, ylabel=ylab, aspect=DataAspect(),
               xticks=xticks, yticks=yticks)
    hm = heatmap!(ax, xcenters, ycenters, wplot; interpolate=false, colormap=colormap, colorrange=cr)

    # Colorbar (LaTeX ticks), width=20
    if isnothing(cbar_ticks)
        Colorbar(fig[1, 2], hm; label=cbar_label, width=20)
    else
        Colorbar(fig[1, 2], hm; label=cbar_label, ticks=cbar_ticks, width=20)
    end

    # Output "<x>_vs_<y>/<x>_vs_<y>.pdf"
    base = string(_sanitize(xname), "_vs_", _sanitize(yname))
    dir  = isnothing(outdir) ? base : String(outdir)
    isdir(dir) || mkpath(dir)
    fname = isnothing(outfile) ? (base * ".pdf") : String(outfile)
    if !endswith(lowercase(fname), ".pdf")
        fname *= ".pdf"
    end
    fullpath = joinpath(dir, fname)

    # Save with Makie
    save(fullpath, fig)
    return (; fig, outfile=fullpath, outdir=dir, xcenters, ycenters, weights=w, histogram=h)
end

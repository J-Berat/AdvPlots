function semicircular_hist(angles_deg; nbins::Int=18, rmax::Float64=1.0, color=:dodgerblue)
    # angles in [0;180)
    angles = mod.(angles_deg, 180)

    # Bins réguliers entre 0 et 180°
    edges = range(0, stop=180, length=nbins+1)
    h = fit(Histogram, angles, edges)
    counts = h.weights
    edges = h.edges[1]

    fig = Figure()
    ax = Axis(fig[1, 1],
        aspect = DataAspect(),
        xticksvisible = false, yticksvisible = false,
        xgridvisible = false, ygridvisible = false,
        xlabel = "", ylabel = "")

    # demi-cercle externe pour le repère
    θ_outline = range(0, stop=pi, length=200)
    lines!(ax, rmax .* cos.(θ_outline), rmax .* sin.(θ_outline), color=:black)

    maxc = maximum(counts)
    maxc == 0 && return fig  # rien à tracer

    # On crée un "secteur" par bin
    for (k, c) in enumerate(counts)
        c == 0 && continue

        θ1 = deg2rad(edges[k])
        θ2 = deg2rad(edges[k+1])
        r  = rmax * (c / maxc)

        θs = range(θ1, stop=θ2, length=30)

        xs = [0.0; r .* cos.(θs); 0.0]
        ys = [0.0; r .* sin.(θs); 0.0]

        poly!(ax, Point2f.(xs, ys), color=color, strokewidth=0)
    end

    hidespines!(ax)
    hidedecorations!(ax, ticks=false, ticklabels=false)

    fig
end

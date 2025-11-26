# ============================================================
# Fold angles into [0, π] and compute a normalized PDF
# ============================================================
function folded_pdf(angles; nbins::Int = 72)
    # Fold all angles into [0, π]
    θ = mod.(angles, π)

    # Histogram over [0, π]
    edges = range(0, stop = π, length = nbins + 1)
    h = fit(Histogram, θ, edges)
    counts = h.weights

    Δθ  = step(edges)
    pdf = counts ./ (sum(counts) * Δθ)   # normalized PDF

    θc = (edges[1:end-1] .+ edges[2:end]) ./ 2  # bin centers
    return θc, pdf
end

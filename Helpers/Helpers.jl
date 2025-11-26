\
# Helpers included into AdvPlots module.

_safe_clims(cr::Tuple{<:Real,<:Real}) = cr[1] == cr[2] ? begin
    δ = max(abs(cr[1]) * 1e-6, 1e-12); (cr[1] - δ, cr[2] + δ)
end : cr

_sanitize(s::AbstractString) = begin
    t = replace(s, r"[^\w\-]+" => "_"); t = replace(t, r"_+" => "_"); strip(t, '_')
end

_latex_var(name::AbstractString) = LaTeXStrings.latexstring("\\mathrm{" * replace(name, "_" => "\\_") * "}")


function _ticks_lin(a::Real, b::Real; n::Int=5)
    if !isfinite(a) || !isfinite(b); return nothing; end
    vals = (a == b) ? [a] : collect(range(a, b; length=n))
    labs = [LaTeXStrings.latexstring("\\mathrm{" * string(round(v, sigdigits=3)) * "}") for v in vals]
    return (vals, labs)
end

function _ticks_log10(cr_log::Tuple{<:Real,<:Real})
    lo, hi = cr_log
    if !isfinite(lo) || !isfinite(hi) || lo >= hi; return nothing; end
    e0 = ceil(Int, lo); e1 = floor(Int, hi)
    e0 > e1 && return nothing
    pos  = Float64.(e0:e1)
    labs = [LaTeXStrings.latexstring("10^{$e}") for e in e0:e1]
    return (pos, labs)
end

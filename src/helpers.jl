# Helpers included into AdvPlots module.

_ensure_positive_for_log(name::AbstractString, values) = begin
    any((!isfinite(v) || v <= 0) for v in values) &&
        throw(ArgumentError("$name must be strictly positive for log scaling"))
end

_validate_range_tuple(r::Tuple{<:Real,<:Real}, label::AbstractString) = begin
    (!all(isfinite, r) || r[1] >= r[2]) &&
        throw(ArgumentError("$label must be finite with the first element smaller than the second"))
    r
end

_validate_nbins_tuple(nbins::Tuple{Int,Int}) = begin
    all(>(0), nbins) || throw(ArgumentError("nbins must be strictly positive"))
    nbins
end

_validate_positive_int(label::AbstractString, value::Integer) = begin
    value > 0 || throw(ArgumentError("$label must be a positive integer"))
    value
end

_validate_outstring(label::AbstractString, path::AbstractString) = begin
    isempty(strip(path)) && throw(ArgumentError("$label cannot be empty"))
    path
end

_safe_clims(cr::Tuple{<:Real,<:Real}) = cr[1] == cr[2] ? begin
    δ = max(abs(cr[1]) * 1e-6, 1e-12)
    (cr[1] - δ, cr[2] + δ)
end : cr

# Handle color limits depending on the requested scale. When `scale` is
# logarithmic, user-provided `clims` must be positive, but automatically
# computed ranges (when `clims === nothing`) are allowed to include the
# logarithm of small positive values.
function _process_clims(clims::Union{Nothing,Tuple{<:Real,<:Real}},
                        scale::Symbol,
                        data_range::Tuple{<:Real,<:Real})
    if scale == :log10
        if isnothing(clims)
            return _safe_clims(data_range)
        end

        all(>(0), clims) || throw(ArgumentError("clims must be > 0 for :log10"))
        return _safe_clims((log10(clims[1]), log10(clims[2])))
    end

    return _safe_clims(isnothing(clims) ? data_range : Tuple(clims))
end


_sanitize(s::AbstractString) = begin
    t = replace(s, r"[^\w\-]+" => "_")
    t = replace(t, r"_+" => "_")
    strip(t, '_')
end

_latex_var(name::AbstractString) = LaTeXStrings.latexstring("\\mathrm{" * replace(name, "_" => "\\_") * "}")

function _ticks_lin(a::Real, b::Real; n::Int=5)
    if !isfinite(a) || !isfinite(b)
        return nothing
    end
    vals = (a == b) ? [a] : collect(range(a, b; length=n))
    labs = [LaTeXStrings.latexstring("\\mathrm{" * string(round(v, sigdigits=3)) * "}") for v in vals]
    return (vals, labs)
end

function _ticks_log10(cr_log::Tuple{<:Real,<:Real})
    lo, hi = cr_log
    if !isfinite(lo) || !isfinite(hi) || lo >= hi
        return nothing
    end
    e0 = ceil(Int, lo)
    e1 = floor(Int, hi)
    e0 > e1 && return nothing
    pos  = Float64.(e0:e1)
    labs = [LaTeXStrings.latexstring("10^{$e}") for e in e0:e1]
    return (pos, labs)
end

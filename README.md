# AdvPlots

AdvPlots is a lightweight Julia package that bundles ready‑to‑use plotting helpers powered by [Makie.jl](https://makie.juliaplots.org/). It collects common 2D density plots, semicircular histograms, folded PDFs, and vector fields to help you produce reproducible scientific figures quickly.

## Quick installation

```bash
cd AdvPlots
julia --project=. deps.jl           # installs recorded dependencies via Pkg.instantiate()
```

To run the test suite and verify the environment:

```bash
julia --project=. -e 'import Pkg; Pkg.test()'
```

## Quick usage

### 2D histogram with auto‑saved PDF

```julia
using AdvPlots, Random, Distributions

Random.seed!(42)
d1 = MvNormal([0.0, 0.0], [1.0 0.6; 0.6 1.5])
d2 = MvNormal([3.0, 2.0], [0.8 -0.3; -0.3 0.5])
xy = vcat(rand(d1, 5_000)', rand(d2, 3_500)')
x = xy[:, 1]; y = xy[:, 2]

result = AdvPlots.hist2d(x, y;
    xname="var1", yname="var2",
    nbins=(60, 60), norm=:pdf, scale=:linear
)
# ➜ Saves a PDF to ./var1_vs_var2/var1_vs_var2.pdf
```

Use `scale = :log10` for a logarithmic colorbar.

### Semicircular histogram

```julia
angles_deg = 0:10:170
fig = AdvPlots.semicircular_hist(angles_deg; nbins=18, rmax=1.0, color=:dodgerblue)
```

### Folded angle PDF

```julia
θc, pdf = AdvPlots.folded_pdf(rand(0:0.01:2π, 10_000); nbins=72)
```

### Quick phase diagram

```julia
fig = AdvPlots.phase_diagram(x_data, y_data;
    T_values=[200, 2000],
    xlabel=L"\log_{10}(n)\,(\mathrm{cm}^{-3})",
    ylabel=L"\log_{10}(P)\,(\mathrm{K\,cm}^{-3})",
    colorbar_label="log_{10}(counts)",
    apply_log=true,
    show_isotherms=true,
    show_Tequ=true
)
```

### Vector fields (quiver)

```julia
fig = AdvPlots.quiver_field_makie(x, y, u, v;
    xlabel="x", ylabel="y",
    color=:magenta, normalize=false,
    outfile="quiver.png",
)
```

To extract and plot a 2D slice from a vector cube:

```julia
AdvPlots.quiver_slice_from_cubes(Bx, By, Bz, xgrid, ygrid, zgrid;
    axis=:z, coord=0.0, every=2,
    colorby=:mag, outfile="slice.png",
)
```

## Included demo

A minimal script in `demo/demo.jl` generates two 2D histogram PDFs:

```bash
julia --project=. demo/demo.jl
```

## Project details

- No separate `test/Project.toml`: tests rely on package extras.
- Package UUID: `4b07f121-2307-42c0-8344-6814ace90e04`.
- Tested with Julia 1.9 and versions listed in `Project.toml`.

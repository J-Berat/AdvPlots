using AdvPlots
using CairoMakie
using Random
using Distributions

Random.seed!(42)

# -----------------
# 2D histograms
# -----------------
d1 = MvNormal([0.0, 0.0], [1.0 0.6; 0.6 1.5])
d2 = MvNormal([3.0, 2.0], [0.8 -0.3; -0.3 0.5])
xy = vcat(rand(d1, 5000)', rand(d2, 3500)')
x = xy[:, 1]; y = xy[:, 2]

println("Plotting 2D histograms ...")
linear = AdvPlots.hist2d(x, y; xname="var1", yname="var2", nbins=(60,60), norm=:pdf, scale=:linear)
log10  = AdvPlots.hist2d(x, y; xname="var1", yname="var2", nbins=(60,60), norm=:pdf, scale=:log10)
println("  • linear scale: $(linear.outfile)")
println("  • log10  scale: $(log10.outfile)")

# -----------------
# Angular statistics
# -----------------
println("Plotting semicircular histogram and folded PDF ...")
angles_deg = rand(Normal(90, 25), 800)
angles_rad = deg2rad.(angles_deg)

mkpath("angles")
fig_angles = AdvPlots.semicircular_hist(angles_deg; nbins=24, rmax=1.0, color=:orangered)
save(joinpath("angles", "semicircular_hist.pdf"), fig_angles)

θc, pdf = AdvPlots.folded_pdf(angles_rad; nbins=48)
fig_pdf = Figure()
ax_pdf = Axis(fig_pdf[1, 1]; xlabel = L"\u03b8\;(\u03c0\;\text{folded})", ylabel = L"p(\u03b8)")
lines!(ax_pdf, θc, pdf, color=:black, linewidth=3)
fig_pdf
save(joinpath("angles", "folded_pdf.pdf"), fig_pdf)
println("  • semicircular histogram: angles/semicircular_hist.pdf")
println("  • folded PDF: angles/folded_pdf.pdf")

# -----------------
# Phase diagram
# -----------------
println("Plotting phase diagram ...")
mkpath("phase_diagram")
x_data = rand(LogNormal(0.0, 0.7), 4000)
y_data = rand(LogNormal(1.2, 0.9), 4000)
fig_phase = AdvPlots.phase_diagram(x_data, y_data;
    title = "Synthetic log10 phase diagram",
    xlabel = "log₁₀(n)",
    ylabel = "log₁₀(P)",
    colorbar_label = "log₁₀(count)",
    apply_log = true,
    show_isotherms = false,
    show_Tequ = false,
    savepath = joinpath("phase_diagram", "phase_diagram.pdf"))
println("  • phase diagram: phase_diagram/phase_diagram.pdf")

# -----------------
# Quiver demo
# -----------------
println("Plotting quiver field ...")
mkpath("quiver")
xs = range(-2.0, 2.0, length=20)
ys = range(-2.0, 2.0, length=20)
xgrid = repeat(xs, inner=length(ys))
ygrid = repeat(ys, outer=length(xs))
u = .-ygrid
v = xgrid
quiver = AdvPlots.quiver_field_makie(xgrid, ygrid, u, v;
    xlabel = "x",
    ylabel = "y",
    color = hypot.(u, v),
    colormap = :plasma,
    colorbarlabel = "|v|",
    backend = :cairo,
    showfig = false,
    outfile = joinpath("quiver", "quiver.png"))
println("  • quiver field: quiver/quiver.png")

println("Demo done. Outputs are stored in ./var1_vs_var2/, ./angles/, ./phase_diagram/ and ./quiver/.")

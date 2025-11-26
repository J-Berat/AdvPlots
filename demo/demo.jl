\
using AdvPlots
using Random
using Distributions

Random.seed!(42)
d1 = MvNormal([0.0, 0.0], [1.0 0.6; 0.6 1.5])
d2 = MvNormal([3.0, 2.0], [0.8 -0.3; -0.3 0.5])
xy = vcat(rand(d1, 5000)', rand(d2, 3500)')
x = xy[:, 1]; y = xy[:, 2]

# Linear
AdvPlots.hist2d(x, y; xname="var1", yname="var2", nbins=(60,60), norm=:pdf, scale=:linear)

# Log10
AdvPlots.hist2d(x, y; xname="var1", yname="var2", nbins=(60,60), norm=:pdf, scale=:log10)

println("Demo done. PDFs are in ./var1_vs_var2/")

\
using Test
using Random
using Distributions
using AdvPlots

@testset "hist2d basics" begin
    Random.seed!(123)
    d1 = MvNormal([0.0, 0.0], [1.0 0.5; 0.5 1.2])
    d2 = MvNormal([3.0, 2.0], [0.6 -0.2; -0.2 0.7])
    xy = vcat(rand(d1, 2000)', rand(d2, 1500)')
    x = xy[:, 1]; y = xy[:, 2]

    r1 = AdvPlots.hist2d(x, y; xname="x", yname="y", nbins=(40,40), norm=:pdf, scale=:linear)
    @test isfile(r1.outfile)
    @test r1.outdir == "x_vs_y"

    r2 = AdvPlots.hist2d(x, y; xname="x", yname="y", nbins=(40,40), norm=:pdf, scale=:log10)
    @test isfile(r2.outfile)

    @test_throws ArgumentError AdvPlots.hist2d(x, y; xname="x", yname="y", scale=:log10, clims=(0.0, 1e-3))
end

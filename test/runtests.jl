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

@testset "hist2d validation" begin
    x = [1.0, 2.0, 3.0]
    y = [1.0, 2.0]
    @test_throws ArgumentError AdvPlots.hist2d(x, y)

    @test_throws ArgumentError AdvPlots.hist2d([1.0, 2.0], [1.0, 2.0]; nbins=(0, 10))
    @test_throws ArgumentError AdvPlots.hist2d([1.0, 2.0], [1.0, 2.0]; norm=:bad)
    @test_throws ArgumentError AdvPlots.hist2d([1.0, 2.0], [1.0, 2.0]; scale=:bad)
    @test_throws ArgumentError AdvPlots.hist2d([1.0, 2.0], [1.0, 2.0]; xrange=(2.0, -1.0))
    @test_throws ArgumentError AdvPlots.hist2d([missing, NaN], [missing, NaN])

    @test_throws ArgumentError AdvPlots.hist2d([1.0, 2.0], [1.0, 2.0]; scale=:log10, clims=(-1.0, 1.0))
end

@testset "hist2d output" begin
    x = [0.2, 0.8, 1.2, 1.6]
    y = [0.2, 0.8, 1.2, 1.6]

    r = mktempdir() do dir
        AdvPlots.hist2d(x, y; nbins=(2, 2), xrange=(0.0, 2.0), yrange=(0.0, 2.0), norm=:pdf,
                         outdir=dir, outfile="simple_plot")
    end

    @test isfile(r.outfile)
    @test endswith(r.outfile, "simple_plot.pdf")
    @test isapprox(r.weights, fill(0.25, 2, 2))
end

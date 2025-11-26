using Test
using Random
using Distributions
using CairoMakie
using AdvPlots

@testset "hist2d basics" begin
    Random.seed!(123)
    d1 = MvNormal([0.0, 0.0], [1.0 0.5; 0.5 1.2])
    d2 = MvNormal([3.0, 2.0], [0.6 -0.2; -0.2 0.7])
    xy = vcat(rand(d1, 2000)', rand(d2, 1500)')
    x = xy[:, 1]; y = xy[:, 2]

    mktempdir() do dir
        r1 = AdvPlots.hist2d(x, y; xname="x", yname="y", nbins=(40,40), norm=:pdf, scale=:linear, outdir=dir)
        @test isfile(r1.outfile)
        @test r1.outdir == dir

        r2 = AdvPlots.hist2d(x, y; xname="x", yname="y", nbins=(40,40), norm=:pdf, scale=:log10, outdir=dir)
        @test isfile(r2.outfile)
    end

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

@testset "hist2d options" begin
    x = rand(1000)
    y = rand(1000)

    mktempdir() do dir
        r_prob = AdvPlots.hist2d(x, y; nbins=(10, 15), norm=:probability, outdir=dir)
        @test size(r_prob.weights) == (10, 15)
        @test minimum(r_prob.weights) ≥ 0
        @test isapprox(sum(r_prob.weights), 1.0; atol=1e-6)

        r_log = AdvPlots.hist2d(x, y; nbins=(12, 8), norm=:pdf, scale=:log10, clims=(1e-5, 1e0), outdir=dir, outfile="log_density")
        @test size(r_log.weights) == (12, 8)
        @test minimum(r_log.weights) ≥ 0
        @test endswith(r_log.outfile, ".pdf")
        @test isfile(r_log.outfile)
    end
end

@testset "phase diagram output" begin
    x = rand(500) .+ 0.1
    y = rand(500) .+ 0.1

    mktempdir() do dir
        savepath = joinpath(dir, "phase_diag.png")
        fig = phase_diagram(x, y; savepath=savepath, colorbar_label="counts", apply_log=true)
        @test isfile(savepath)
        @test fig isa Figure
    end
end

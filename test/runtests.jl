
using Drawing

using Base.Test
using SHA: sha1
using Images
using Colors

include("cairo.jl")

MAX_DIFF = 8

function compare(name)
    print("$(name): ")
    im1 = imread(name)
    im2 = imread("target/$(name)")
    @test size(im1) == size(im2)
    for c in zip(im1, im2)
        c1, c2 = c
        d = colordiff(c1, c2)
        if d >= MAX_DIFF
            println("$c1 $c2 $(colordiff(c1, c2))")
            @test colordiff(c1, c2) < MAX_DIFF
        end
    end
    println("ok")
end    

function axes()
    move(0,0)
    line(1,0)
    move(0,0)
    line(0,1)
end

include("basics.jl")
include("shapes.jl")
include("text.jl")
include("errors.jl")
include("towers.jl")

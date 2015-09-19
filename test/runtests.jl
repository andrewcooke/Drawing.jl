
using Drawing

using Base.Test
using SHA: sha1

include("cairo.jl")

function compare(name)
    print("$(name): ")
    h1 = open(name, "r") do f
        sha1(readall(f))
    end
    h2 = open("target/$(name)", "r") do f
        sha1(readall(f))
    end
    @test h1 == h2
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

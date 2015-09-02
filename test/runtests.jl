
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

include("basics.jl")
include("towers.jl")

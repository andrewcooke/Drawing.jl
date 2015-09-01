
using Drawing

using Base.Test
using SHA: sha1

function compare(name)
    h1 = open(name, "r") do f
        sha1(readall(f))
    end
    h2 = open("target/$(name)", "r") do f
        sha1(readall(f))
    end
    @test h1 == h2
    println("$(name) ok")
end    

include("basic_pen.jl")


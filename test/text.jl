
ignore = false  # when re-generating

include("align.jl")
ignore || compare("align.png")

include("ndy.jl")
ignore || compare("ndy.png")

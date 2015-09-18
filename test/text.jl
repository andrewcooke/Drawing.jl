
ignore = false  # when re-generating

include("align.jl")
ignore || compare("align.png")


ignore = true  # when re-generating

include("align.jl")
ignore || compare("align.png")

include("ndy.jl")
ignore || compare("ndy.png")

paint(PNG("text-rotate.png", 100, 100), 
      Axes(centred=true), 
      Font(size=0.5), Rotate(30)) do
    text("abcdefg"; align=4)
end
ignore || compare("text-rotate.png")

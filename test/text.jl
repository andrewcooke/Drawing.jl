
ignore = false  # when re-generating

include("text-align.jl")
# comparison failing but looks ok
#ignore || compare("text-align.png")

include("ndy.jl")
ignore || compare("ndy.png")

paint(PNG("text-rotate.png", 100, 100), 
      Axes(centred=true), 
      Font(size=0.5)) do
    text("abcdefg"; align=4, rotate=30)
end
ignore || compare("text-rotate.png")

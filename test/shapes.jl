
using Drawing

ignore = false  # when re-generating

with(PNG("square-align.png", 100, 100), Axes(negative=true)) do
    draw() do
        square(0.6, align=9)
        square(0.8, align=5)
        square(1.0, align=1)
    end
end
ignore || compare("square-align.png")

with(PNG("rectangle-align.png", 100, 100), Axes(negative=true)) do
    draw() do
        rectangle(0.6, 0.3, align=9)
        rectangle(0.8, 0.4, align=5)
        rectangle(1.0, 0.5, align=1)
    end
end
ignore || compare("rectangle-align.png")


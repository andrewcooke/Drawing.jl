
draw(PNG("portrait.png", 100, 140),
     Paper("lightgrey"),
     Axes(centred=false)) do
    move(0, 0)
    line(1, 0)
    move(0, 0)
    line(0, 1)
end

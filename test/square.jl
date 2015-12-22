
draw(PNG("square.png", 140, 100), 
     Paper("lightgrey"),
     Axes(centred=false)) do
    move(0, 0)
    square(1, align=7)
end

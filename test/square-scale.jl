
draw(PNG("square-scale.png", 140, 100), 
     Paper("lightgrey"),
     Scale(0.5)) do
    move(0, 0)
    line(1, 0)
    line(1, 1)
    line(0, 1)
    line(0, 0)
end

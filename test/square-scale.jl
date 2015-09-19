
draw(PNG("square-scale.png", 140, 100), 
     Paper("lightgrey"),
     Scale(0.5)) do
    move(0, 0)
    square(1, align=7)
end

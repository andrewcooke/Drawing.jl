
draw(PNG("square-rotate.png", 140, 100), 
     Paper("lightgrey"),
     Rotate(45)) do
    move(0, 0)
    line(1, 0)
    line(1, 1)
    line(0, 1)
    line(0, 0)
end


draw(PNG("square-rotate.png", 140, 100), 
     Paper("lightgrey"),
     Axes(centred=false)) do
    square(1, align=7, rotate=45)
end

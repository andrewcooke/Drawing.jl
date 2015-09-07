
draw(PNG("square-bevel.png", 140, 100), 
     Axes(border=0.2),
     Paper("lightgrey"), 
     Pen(0.3, cap="square", join="bevel")) do
    move(0, 0)
    line(0.5, 0)
    line(0.5, 0.5)
    line(1, 1)
end

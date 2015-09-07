
draw(PNG("butt-mitre.png", 140, 100), 
     Axes(border=0.2),
     Paper("lightgrey"), 
     Pen(0.3, cap="butt", join="mitre")) do
    move(0, 0)
    line(0.5, 0)
    line(0.5, 0.5)
    line(1, 1)
end


draw(PNG("round-round.png", 140, 100), 
     Axes(border=0.2),
     Paper("lightgrey"), 
     Pen(0.3, cap="round", join="round")) do
    move(0, 0)
    line(0.5, 0)
    line(0.5, 0.5)
    line(1, 1)
end

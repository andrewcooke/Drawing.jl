
draw(File("a10-butt-mitre.png"), 
     Paper("a10"; dpi=100, orientation="landscape", border=0.2, background="lightgrey"), 
     Scale(100), 
     Pen(0.003, cap="butt", join="mitre")) do
    move(0, 0)
    line(0.005, 0)
    line(0.005, 0.005)
    line(0.01, 0.01)
end


draw(File("a10-round-round.png"), 
     Paper("a10"; dpi=100, orientation="landscape", border=0.2, background="lightgrey"), 
     Pen(0.3, cap="round", join="round")) do
    move(0, 0)
    line(0.5, 0)
    line(0.5, 0.5)
    line(1, 1)
end

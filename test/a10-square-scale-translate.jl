
draw(File("a10-square-scale-translate.png"), 
     Paper("a10"; dpi=100, orientation="landscape", border=0.1, background="lightgrey"),
     Scale(0.5), Translate(1, 1)) do
    move(0, 0)
    line(1, 0)
    line(1, 1)
    line(0, 1)
    line(0, 0)
end

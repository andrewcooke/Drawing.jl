
# http://julialang.org/blog/2013/05/graphical-user-interfaces-part2/

using Graphics
using Cairo
using Tk

win = Toplevel("Test", 400, 200)
c = Canvas(win)
pack(c, expand=true, fill="both")
ctx = getgc(c)
# Set coordinates to go from 0 to 10 within a 300x100 centered region
set_coords(ctx, 50, 50, 300, 100, 0, 10, 0, 10)
set_source_rgb(ctx, 0, 0, 1)   # set color to blue
paint(ctx)                     # paint the entire clip region
move_to(ctx, -1, 5)
line_to(ctx, 7, 6)
set_source_rgb(ctx, 1, 0, 0)
set_line_width(ctx, 5)
stroke(ctx)
reveal(c)
Tk.update()
reset_clip(ctx)
rectangle(ctx, 7, 5, 4, 4)
set_source_rgb(ctx, 0, 1, 0)
fill_preserve(ctx)
set_source_rgb(ctx, 1, 0, 1)
stroke(ctx)
reveal(c)
Tk.update()


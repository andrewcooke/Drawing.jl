
using Cairo
using Colors
using Graphics

ctx = CairoContext(CairoRGBSurface(100, 100))

save(ctx)
rectangle(ctx, 0, 0, 100, 100)
set_source(ctx, parse(Colorant, "white"))
fill(ctx)
restore(ctx)

set_coords(ctx, 0, 0, 100, 100, -0.125, 1.125, 1.125, -0.125)
set_line_width(ctx, 5)

set_source(ctx, parse(Colorant, "red"))
move_to(ctx, 0, 0)
line_to(ctx, 1, 0)
line_to(ctx, 1, 1)
stroke(ctx)

set_source(ctx, parse(Colorant, "orange"))
move_to(ctx, 1, 1)
line_to(ctx, 0, 1)
line_to(ctx, 0, 0)
stroke(ctx)

write_to_png(ctx.surface, "bar.png")

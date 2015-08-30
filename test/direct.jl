
using Cairo
using Colors
using Graphics

ctx = CairoContext(CairoRGBSurface(3508, 2480))
save(ctx)
rectangle(ctx, 0, 0, 3508, 2480)
set_source(ctx, parse(Colorant, "white"))
fill(ctx)
restore(ctx)
set_coords(ctx, 0, 0, 3508, 2480, -0.125, 1.642857142857143, 1.125, -0.125)
#set_coords(ctx, 0, 0, 3508, 2480, 0, 2, 2, 0)
set_source(ctx, parse(Colorant, "red"))
v = [0.1, 0.1]
user_to_device_distance!(ctx, v)
println(v)
set_line_width(ctx, v[1] > v[2] ? v[1] : v[2])
x = 1
move_to(ctx, 0, 0)
line_to(ctx, x, 0)
line_to(ctx, x, x)
line_to(ctx, 0, x)
line_to(ctx, 0, 0)
stroke(ctx)
write_to_png(ctx.surface, "bar.png")


import Cairo; const X = Cairo
import Graphics; const G = Graphics
import Colors; const C = Colors

# so, from this we learn that:
# - if the output attribute comes first, we cna handle pdf and png
# - after that, background must come before drawing, but can be mixed
#   with axes.
# - output can set its own axes too, for defaults.
# - heck, it can even set its own background and ink
# - "number of pixels" is defined for png, but not for pdf (duh!)
# in total, then, we need the following stages
# - initial, uninitialized
# - output set (with default coords, default background, default ink)
# - optional paper (background) and axes (these are "absolute" so override)
# - drawing stuff
# where only the first is required.  for the rest, only order matters.
# (ie don't allow baackground or axes once drawwing has started)

function background(ctx)
#    X.save(ctx)
    G.set_coords(ctx, 0, 0, X.width(ctx.surface), X.height(ctx.surface), 0, 1, 0, 1)
    X.rectangle(ctx, 0, 0, 1, 1)
    X.set_source(ctx, parse(C.Colorant, "red"))
    X.fill(ctx)
#    X.restore(ctx)
end

function diagonal(ctx)
    X.set_source(ctx, parse(C.Colorant, "blue"))
    G.set_coords(ctx, 0, 0, X.width(ctx.surface), X.height(ctx.surface), 0, 1, 0, 1)
    X.move_to(ctx, 0, 0)
    X.line_to(ctx, 0.5, 0.5)
    X.stroke(ctx)
end

function rnadom_crap(ctx)
    X.scale(ctx, 0.5, 0.5)
    X.rotate(ctx, pi/2)
end

function middle_bit(ctx)
    # this stuff no longer fucks up the background, because it sets its own
    # coords
    random_crap(ctx)
    # but the order of these is still important if you want to see both
    background(ctx)
    random_crap(ctx)
    diagonal(ctx)
end

ctx = X.CairoContext(X.CairoPDFSurface("formats.pdf", 3*72, 2*72))
middle_bit(ctx)
X.destroy(ctx)

ctx = X.CairoContext(X.CairoRGBSurface(300, 200))
middle_bit(ctx)
X.write_to_png(ctx.surface, "formats.png")
X.destroy(ctx)


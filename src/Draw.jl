
module Draw

import Cairo; const X = Cairo
import Graphics; const G = Graphics
import Colors; const C = Colors

export with, Paper, Pen, move, line, save

abstract Scope

typealias NullableContext Nullable{X.CairoContext}

# this needs to be in a thread local variable once such things exist in julia
type ThreadContext
    context::Nullable{X.CairoContext}
    ThreadContext() = new(NullableContext())
end

thread_context = ThreadContext()
current_context() = get(thread_context.context)

# TODO - support other types
parse_color(c) = parse(C.Colorant, c)

function with(f, scopes::Scope...)
    c = thread_context
    for scope in scopes
        enter(c, scope)
    end
    f()
    for scope in reverse(scopes)
        exit(c, scope)
    end
end

type Pen <: Scope
    foreground::C.Color
    width::Float64
end

Pen(foreground; width=0.02) = Pen(parse_color(foreground), width)

function enter(c, p::Pen)
    ctx = current_context()
    X.set_source(ctx, p.foreground)
    w = [p.width, p.width]
    X.user_to_device_distance!(ctx, w)
    w = maximum(map(abs, w))
    X.set_line_width(ctx, w)
end

function exit(c, p::Pen)
    ctx = current_context()
    X.stroke(ctx)
end

type Paper <: Scope
    nx::Int
    ny::Int
    xl::Float64
    xr::Float64
    yb::Float64
    yt::Float64
    background::C.Color
    Paper(nx, ny, xl, xr, yb, yt, bg) = new(nx, ny, xl, xr, yb, yt, bg)
    previous_context::NullableContext
end

immutable Orientation enumeration end
const LANDSCAPE = Orientation(1)
const PORTRAIT = Orientation(2)

function paper_size(size::AbstractString)
    if lowercase(size) == "a4"
        [210,297]
    else
        throw(ValueError("unknown paper size: $(size)"))
    end
end

int(x) = round(Int, x)

function Paper(size::AbstractString; dpi=300::Int, background="white", 
               orientation=LANDSCAPE::Orientation, border=0.1::Float64,
               scale=1.0::Float64)
    bg = parse_color(background)
    d = scale / (1.0 - 2*border)
    b = (d - scale) / 2
    nx, ny = dpi * paper_size(size) / 25.4
    if orientation == PORTRAIT
        Paper(int(nx), int(ny), -b, scale+b, -b, (ny/nx)*d - b, bg)
    else
        nx, ny = ny, nx
        Paper(int(nx), int(ny), -b, (nx/ny)*d - b, -b, scale+b, bg)
    end
end

function enter(c, p::Paper)
    ctx = X.CairoContext(X.CairoRGBSurface(p.nx, p.ny))
    p.previous_context = c.context
    c.context = NullableContext(ctx)

    X.save(ctx)
    X.rectangle(ctx, 0, 0, p.nx, p.ny)
    X.set_source(ctx, p.background)
    X.fill(ctx)
    X.restore(ctx)
    X.set_coords(ctx, 0, 0, p.nx, p.ny, p.xl, p.xr, p.yt, p.yb)
end

# TODO - replace context
exit(c, p::Paper) = nothing

macro lift(new, old)
    :($(esc(new))(args...) = $(esc(old))(current_context(), args...))
end

@lift(move, X.move_to)
@lift(line, X.line_to)

# TODO - other formats
function save(path::AbstractString)
    X.write_to_png(current_context().surface, path)
end

end


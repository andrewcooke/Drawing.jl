
module Drawing

import Cairo; const X = Cairo
import Graphics; const G = Graphics
import Colors; const C = Colors

export with, Paper, File, Pen, move, line, save



# --- global / thread-local state

typealias NullableContext Nullable{X.CairoContext}

# this needs to be in a thread local variable once such things exist in julia
type ThreadContext
    context::NullableContext
    ThreadContext() = new(NullableContext())
end

thread_context = ThreadContext()
current_context() = get(thread_context.context)



# --- scoping infrastructure

"""
Scoped values, used with `with() do ... end`, to define some property of 
the drawing within the do block.  All Scope subtypes must implement 
`rank()` so that they can be sorted correctly within `with()`.
"""
abstract Scope

"""
Call `enter()` for each Scope, then execute the do block, and finally call
`exit()` for each Scope.
"""
function with(f, scopes::Scope...)
    # stable sort, respecting user where possible
    s = sort!([scopes...], by=rank, alg=InsertionSort)
    c = thread_context
    for scope in s
        enter(c, scope)
    end
    f()
    for scope in reverse(s)
        exit(c, scope)
    end
end



# --- utilities

parse_color(c::AbstractString) = parse(C.Colorant, c)
parse_color(c::C.Color) = c

int(x) = round(Int, x)



# --- paper declaration

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

rank(::Paper) = 10

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

exit(c, p::Paper) = c.context = p.previous_context



# --- output (file, display, etc)

type File <: Scope
    path::AbstractString
end

rank(::File) = 20  # after Paper (which sets the context), but before content

enter(c, ::File) = nothing

# TODO - other formats
function exit(c, f::File)
    ctx = get(c.context)
    X.write_to_png(ctx.surface, f.path)
end



# --- line plotting

type Pen <: Scope
    foreground::C.Color
    width::Float64
end

Pen(foreground; width=-1) = Pen(parse_color(foreground), width)

rank(::Pen) = 30

function enter(c, p::Pen)
    ctx = get(c.context)
    X.set_source(ctx, p.foreground)

    if p.width >= 0
        # width is in user coords, so scale to device coords
        v = [p.width, p.width]
        X.user_to_device_distance!(ctx, v)
        w = maximum(map(abs, v))
        X.set_line_width(ctx, w)
    else
        # use 2% of smaller dimension
        d = min(ctx.surface.width, ctx.surface.height)
        X.set_line_width(ctx, d * 0.02)
    end
end

function exit(c, p::Pen)
    ctx = get(c.context)
    X.stroke(ctx)
end



# --- paths

macro lift(new, old)
    :($(esc(new))(args...) = $(esc(old))(current_context(), args...))
end

@lift(move, X.move_to)
@lift(line, X.line_to)

end

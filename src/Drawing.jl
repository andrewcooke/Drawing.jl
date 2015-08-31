
module Drawing

import Cairo; const X = Cairo
import Graphics; const G = Graphics
import Colors; const C = Colors

export with, Paper, File, Pen, move, line



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

abstract Scope

# Scope that can create the initial context
abstract CreatingScope <:Scope

rank(s::CreatingScope) = 0
exclusive(s::CreatingScope) = true

# Scope that modifies the intitial context via actions (before and after)
type ExistingScope <: Scope
    name::AbstractString
    rank::Int
    exclusive::Bool
    before::Vector{Function}
    after::Vector{Function}
    function ExistingScope(name, rank, exclusive, before, after)
        @assert rank > 0
        new(name, rank, exclusive, before, after)
    end
end

name(s::ExistingScope) = s.name
rank(s::ExistingScope) = s.rank
exclusive(s::ExistingScope) = s.exclusive
before(s::ExistingScope) = s.before
after(s::ExistingScope) = s.after

function with(f, scopes::Scope...)

    # stable sort, respecting user where possible
    s = sort!([scopes...], by=rank, alg=InsertionSort)
    c = thread_context

    # TODO - check for exclusive conflicts (and implement name())

    if isnull(c.context) && (length(s) == 0 || !isa(s[1], CreatingScope))
        s = [Paper(), s...]
    end

    for scope in s
        for b in before(scope)
            if isa(scope, CreatingScope)
                b(c)
            else
                b(get(c.context))
            end
        end
    end
    f()
    for scope in reverse(s)
        for a in after(scope)
            if isa(scope, CreatingScope)
                a(c)
            else
                a(get(c.context))
            end
        end
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

type Paper <: CreatingScope
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

Paper() = Paper("a4")

function before(p::Paper)
    [c -> begin
     ctx = X.CairoContext(X.CairoRGBSurface(p.nx, p.ny))
     p.previous_context = c.context
     c.context = NullableContext(ctx)
     
     X.save(ctx)
     X.rectangle(ctx, 0, 0, p.nx, p.ny)
     X.set_source(ctx, p.background)
     X.fill(ctx)
     X.restore(ctx)
     X.set_coords(ctx, 0, 0, p.nx, p.ny, p.xl, p.xr, p.yt, p.yb)
     end]
end
     
after(p::Paper) = [c -> c.context = p.previous_context]



# --- output (file, display, etc)

# TODO - other formats
function File(path::AbstractString)
    ExistingScope("File", 1, false, Function[],
                  [c -> X.write_to_png(c.surface, path)])
end



# --- line plotting

function Pen(foreground; width=-1)
    f = parse_color(foreground)
    ExistingScope("Pen", 2, true, 
                  [c -> X.set_source(c, f), c -> set_width(c, width)],
                  [c -> X.stroke(c)])
end

function set_width(c, width)
    if width >= 0
        # width is in user coords, so scale to device coords
        v = [width, width]
        X.user_to_device_distance!(c, v)
        w = maximum(map(abs, v))
        X.set_line_width(c, w)
    else
        # use 2% of smaller dimension
        d = min(c.surface.width, c.surface.height)
        X.set_line_width(c, d * 0.02)
    end
end



# --- paths

macro lift(new, old)
    :($(esc(new))(args...) = $(esc(old))(current_context(), args...))
end

@lift(move, X.move_to)
@lift(line, X.line_to)

end


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
type CreatingScope <:Scope
    name::AbstractString
    create::Function
    before::Vector{Function}
    after::Vector{Function}
    previous_context::NullableContext
    CreatingScope(name, create, before, after) = new(name, create, before, after, NullableContext())
end

name(s::CreatingScope) = s.name
rank(s::CreatingScope) = 0
exclusive(s::CreatingScope) = true
create(s::CreatingScope) = s.create
before(s::CreatingScope) = s.before
after(s::CreatingScope) = s.after

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

const NO_ACTIONS = Function[]

function with(f, scopes::Scope...)

    # stable sort, respecting user where possible
    s = sort!([scopes...], by=rank, alg=InsertionSort)
    c = thread_context

    # TODO - check for exclusive conflicts (and implement name())

    if isnull(c.context) && (length(s) == 0 || !isa(s[1], CreatingScope))
        s = [Paper(), s...]
    end

    for scope in s
        if isa(scope, CreatingScope)
            scope.previous_context = c.context
            c.context = create(scope)()
        end
        for b in before(scope)
            b(get(c.context))
        end
    end
    f()
    for scope in reverse(s)
        for a in after(scope)
            a(get(c.context))
        end
        if isa(scope, CreatingScope)
            c.context = scope.previous_context
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

function Paper(size::AbstractString; dpi=300::Int, background="white", 
               orientation=LANDSCAPE::Orientation, border=0.1::Float64,
               scale=1.0::Float64)
    bg = parse_color(background)
    nx, ny = map(int, dpi * paper_size(size) / 25.4)
    CreatingScope("Paper",
                  () -> X.CairoContext(X.CairoRGBSurface(nx, ny)),
                  [c -> set_background(c, nx, ny, bg),
                   c -> set_coords(c, orientation, nx, ny, scale, border)],
                  NO_ACTIONS)
end

function paper_size(size::AbstractString)
    if lowercase(size) == "a4"
        [210,297]
    else
        throw(ValueError("unknown paper size: $(size)"))
    end
end

function set_background(c, nx, ny, bg)
    X.save(c)
    X.rectangle(c, 0, 0, nx, ny)
    X.set_source(c, bg)
    X.fill(c)
    X.restore(c)
end

function set_coords(c, orientation, nx, ny, scale, border)
    d = scale / (1.0 - 2*border)
    b = (d - scale) / 2
    if orientation == PORTRAIT
        X.set_coords(c, 0, 0, nx, ny, -b, scale+b, (ny/nx)*d - b, -b)
    else
        X.set_coords(c, 0, 0, ny, nx, -b, (ny/nx)*d - b, scale+b, -b)
    end
end

Paper() = Paper("a4")



# --- output (file, display, etc)

# TODO - other formats
function File(path::AbstractString)
    ExistingScope("File", 1, false, NO_ACTIONS,
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

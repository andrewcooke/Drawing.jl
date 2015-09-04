
module Drawing

import Cairo; const X = Cairo
import Graphics; const G = Graphics
import Colors; const C = Colors

export has_current_point, get_current_point, 
       current_context,
       with, draw, paint,
       Paper, File, Pen, Ink, Scale, Translate, Rotate,
       move, line

include("cairo.jl")

# TODO
# - composability
# - defaults if we declare nothing
# - enforcing scope nesting rules (validation)
# _ more pen attributes (cap style, mitre, etc)
# - fancy sources
# - text
# - curves
# - docs, docs, docs
# - other output formats
# - other paper sizes


# --- global / thread-local state

typealias NullableContext Nullable{X.CairoContext}

const SCOPE_NONE = 0
const SCOPE_WITH = 1
const SCOPE_ACTION = 2

# this needs to be in a thread local variable once such things exist in julia
type ThreadContext
    context::NullableContext
    scope::Vector{Int}
    ThreadContext() = new(NullableContext(), Int[SCOPE_NONE])
end

thread_context = ThreadContext()
current_context() = get(thread_context.context)



# --- scoping infrastructure

const RANK_BOOTSTRAP = 0
const RANK_OUTPUT = 1
const RANK_STATE = 2

# before and after are functions of (ThreadContext, State) -> nothing
type State
    name::AbstractString
    rank::Int
    before::Vector{Function}
    after::Vector{Function}
    State(name, rank, before, after) = new(name, rank, before, after)
end

const NO_ACTIONS = Function[]
ctx(f) = (c, s) -> f(get(c.context))
NO_ACTION = c -> nothing


function make_scope(verify, before, after)

    function scope(f, states::State...)

        # stable sort, respecting user where possible
        s = sort!([states...], by=s -> s.rank, alg=InsertionSort)
        c = thread_context
        
        # save context if it exists
        saved = false
        if c.scope[end] != SCOPE_NONE
            X.save(get(c.context))
            saved = true
        end

        # check for exclusive conflicts and set scope
        verify(c, s)

        for state in s
            for b in state.before
                b(c, state)
            end
            # or save as soon as we have a context (first thing that happens)
            if !saved
                X.save(get(c.context))
                saved = true
            end
        end

        before(get(c.context))

        f()

        after(get(c.context))

        for state in reverse(s)
            for a in state.after
                a(c, state)
            end
        end

        pop!(c.scope)
        if c.scope[end] != SCOPE_NONE
            X.restore(get(c.context))
        end
        
    end
end



# --- scopes

function with_current_point(action)
    function (c)
        has_point = has_current_point(c)
        x, y = get_current_point(c)
        action(c)
        if has_point
            X.move_to(c, x, y)
        end
    end
end    

stroke = with_current_point(X.stroke)
fill = with_current_point(X.fill)

function verify(c,s)
    push!(c.scope, SCOPE_WITH)
end

with = make_scope(verify, NO_ACTION, NO_ACTION)
draw = make_scope(verify, NO_ACTION, stroke)
paint = make_scope(verify, NO_ACTION, fill)



# --- utilities

parse_color(c::AbstractString) = parse(C.Colorant, c)
parse_color(c::C.Color) = c

int(x) = round(Int, x)



# --- paper declaration

immutable Orientation enumeration end
const LANDSCAPE = Orientation(1)
const PORTRAIT = Orientation(2)

# it's OK (necessary, even) for this to have non-null defaults, because it's
# setting up a completely new context (unlike other scopes, which are simply
# modifying some part).

function Paper(nx::Int, ny::Int; background="white", border=0.1::Float64,
               centred=false::Bool)
    bg = parse_color(background)
    State("Paper", RANK_BOOTSTRAP,
          [(c, s) -> c.context = X.CairoContext(X.CairoRGBSurface(nx, ny)),
           ctx(c -> set_background(c, nx, ny, bg)),
           ctx(c -> set_coords(c, nx, ny, border, centred))],
          [(c, s) -> c.context = NullableContext()])
end

function Paper(size::AbstractString; dpi=300::Int, background="white", 
               orientation=LANDSCAPE::Orientation, border=0.1::Float64,
               centred=false::Bool)
    nx, ny = map(int, dpi * paper_size(size) / 25.4)
    if orientation == LANDSCAPE
        nx, ny = ny, nx
    end
    Paper(nx, ny; background=background, border=border, centred=centred)
end

# these should be as portrait, in mm (x, y)
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
    println(bg)
    X.set_source(c, bg)
    X.fill(c)
    X.restore(c)
end

function set_coords(c, nx::Int, ny::Int, border::Float64, centred::Bool)
    if centred
        d = 2 / (1 - 2*border)
        b = (d - 2) / 2
        if nx < ny  # portrait
            G.set_coords(c, 0, 0, nx, ny, -1-b, 1+b, (ny/nx)+b, -(ny/nx)-b)
        else
            G.set_coords(c, 0, 0, nx, ny, -(nx/ny)-b, (nx/ny)+b, 1+b, -1-b)
        end
    else
        d = 1 / (1 - 2*border)
        b = (d - 1) / 2
        if nx < ny  # portrait
            G.set_coords(c, 0, 0, nx, ny, -b, 1+b, (ny/nx)*d - b, -b)
        else
            G.set_coords(c, 0, 0, nx, ny, -b, (nx/ny)*d - b, 1+b, -b)
        end
    end
end

Paper() = Paper("a4")



# --- output (file, display, etc)

function File(path::AbstractString)
    State("File", RANK_OUTPUT, NO_ACTIONS,
          [ctx(c -> X.write_to_png(c.surface, path))])
end



# --- source attributes

function Ink(foreground)
    f = parse_color(foreground)
    State("Ink", RANK_STATE, [ctx(c -> X.set_source(c, f))], NO_ACTIONS)
end

Ink() = Ink("black") 



# --- stroke attributes

Pen(width) = State("Pen", RANK_STATE, [ctx(c -> set_width(c, width))], NO_ACTIONS)

Pen() = Pen(-1)

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



# --- transforms

Scale(k) = State("Scale", RANK_STATE, [ctx(c -> X.scale(c, k, k))], NO_ACTIONS)
Scale(x, y) = State("Scale", RANK_STATE, [ctx(c -> X.scale(c, x, y))], NO_ACTIONS)
Translate(x, y) = State("Translate", RANK_STATE, [ctx(c -> X.translate(c, x, y))], NO_ACTIONS)
Rotate(d) = State("Rotate", RANK_STATE, [ctx(c -> X.rotate(c, d))], NO_ACTIONS)



# --- paths

macro lift(new, old)
    :($(esc(new))(args...) = $(esc(old))(current_context(), args...))
end

@lift(move, X.move_to)
@lift(line, X.line_to)

end

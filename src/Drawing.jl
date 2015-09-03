
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
# - translate, scale, rotate (but not general affine transforms)
# - docs, docs, docs



# --- global / thread-local state

typealias NullableContext Nullable{X.CairoContext}

const LEVEL_INITIAL = 0
const LEVEL_COMPOSE = 1
const LEVEL_PATH = 2

# this needs to be in a thread local variable once such things exist in julia
type ThreadContext
    context::NullableContext
    level::Int
    ThreadContext() = new(NullableContext(), LEVEL_INITIAL)
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
    previous_context::NullableContext  # only used at rank 0
    State(name, rank, before, after) = new(name, rank, before, after, NullableContext())
end

const NO_ACTIONS = Function[]
to_ctx(f) = (c, s) -> f(get(c.context))
NO_ACTION = c -> nothing


function make_scope(verify, before, after)

    function scope(f, states::State...)

        # stable sort, respecting user where possible
        s = sort!([states...], by=s -> s.rank, alg=InsertionSort)
        c = thread_context
        
        # outermost context must define paper
        initial, saved = isnull(c.context), false
        if initial
            if length(s) == 0 || s[1].rank != RANK_BOOTSTRAP
                s = [Paper(), s...]
            end
        else
            X.save(get(c.context))
            saved = true
        end
        
        # check for exclusive conflicts
        verify(c)
        
        for state in s
            for b in state.before
                b(c, state)
            end
            # save as soon as we have a context
            if !saved && !isnull(c.context)
                X.save(get(c.context))
                saved = true
            end
        end

        before(get(c.context))
        f()
        after(get(c.context))

        for state in reverse(s)
            # restore (unsave) before replacing context
            if initial && state.rank == RANK_BOOTSTRAP && saved
                X.restore(get(c.context))
                saved = false
            end
            for a in state.after
                a(c, state)
            end
        end

        if saved
            X.restore(get(c.context))
            saved = false
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

with = make_scope(NO_ACTION, NO_ACTION, NO_ACTION)
draw = make_scope(NO_ACTION, NO_ACTION, stroke)
paint = make_scope(NO_ACTION, NO_ACTION, fill)


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
          [(c, s) -> (s.previous_context = c.context; c.context = X.CairoContext(X.CairoRGBSurface(nx, ny))),
           to_ctx(c -> set_background(c, nx, ny, bg)),
           to_ctx(c -> set_coords(c, nx, ny, border, centred))],
          NO_ACTIONS)
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

# TODO - more sizes
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

# TODO - other formats
function File(path::AbstractString)
    State("File", RANK_OUTPUT,
          NO_ACTIONS,
          [to_ctx(c -> X.write_to_png(c.surface, path))])
end



# --- source attributes

function Ink(foreground)
    f = parse_color(foreground)
    State("Ink", RANK_STATE, 
          [to_ctx(c -> X.set_source(c, f))],
          NO_ACTIONS)
end

Ink() = Ink("black") 



# --- stroke attributes

function Pen(width)
    State("Pen", RANK_STATE, 
          [to_ctx(c -> set_width(c, width))],
          NO_ACTIONS)
end

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

function Scale(k)
    State("Scale", RANK_STATE,
          [to_ctx(c -> X.scale(c, k, k))],
          NO_ACTIONS)
end

function Translate(x, y)
    State("Translate", RANK_STATE,
          [to_ctx(c -> X.translate(c, x, y))],
          NO_ACTIONS)
end

function Rotate(d)
    State("Rotate", RANK_STATE,
          [to_ctx(c -> X.rotate(c, d))],
          NO_ACTIONS)
end



# --- paths

macro lift(new, old)
    :($(esc(new))(args...) = $(esc(old))(current_context(), args...))
end

@lift(move, X.move_to)
@lift(line, X.line_to)

end

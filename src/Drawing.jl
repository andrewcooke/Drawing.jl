
module Drawing

import Cairo; const X = Cairo
import Graphics; const G = Graphics
import Colors; const C = Colors

export DrawingError, has_current_point, get_current_point, 
       current_context,
       with, draw, paint,
       Paper, File, Pen, Ink, Scale, Translate, Rotate,
       move, line

include("cairo.jl")

type DrawingError <: Exception 
    msg::AbstractString
end
Base.showerror(io::IO, e::DrawingError) = print(io, e.msg)

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
# - actins that take lists of points (or generators?)


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

# before and after are functions of (ThreadContext, Attribute) -> nothing
type Attribute
    name::AbstractString
    rank::Int
    before::Vector{Function}
    after::Vector{Function}
    Attribute(name, rank, before, after) = new(name, rank, before, after)
end

const NO_ACTIONS = Function[]
ctx(f) = (c, a) -> f(get(c.context))
NO_ACTION = c -> nothing


function make_scope(verify, before, after)

    function scope(f, attributes::Attribute...)

        c = thread_context
        saved = false
        verified = false

        try

            # stable sort, respecting user where possible
            a = sort!([attributes...], by=a -> a.rank, alg=InsertionSort)
                
            # save context if it exists
            if c.scope[end] != SCOPE_NONE
                X.save(get(c.context))
                saved = true
            end
            
            # check for exclusive conflicts and set scope
            verify(c, a)
            verified = true
            
            for attribute in a
                for x in attribute.before
                    x(c, attribute)
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
            
            for attribute in reverse(a)
                for x in attribute.after
                    x(c, attribute)
                end
            end
            
        finally

            verified && pop!(c.scope)
            if c.scope[end] == SCOPE_NONE
                c.context = NullableContext()
            else
                saved && X.restore(get(c.context))
            end
            
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

function verify_bootstrap(c, a)
    if c.scope[end] == SCOPE_NONE && (length(a) == 0 || a[1].rank != RANK_BOOTSTRAP)
        splice!(a, 1:0, [Paper()])
    end
end

function verify_nesting(c, a)
    if c.scope[end] == SCOPE_ACTION 
        throw(DrawingError("Cannot nest a scope inside an action scope"))
    end
end

function make_verify(scope)
    function verify(c, a)
        verify_bootstrap(c, a)
        verify_nesting(c, a)
        push!(c.scope, scope)
    end
end

with = make_scope(make_verify(SCOPE_WITH), NO_ACTION, NO_ACTION)
draw = make_scope(make_verify(SCOPE_ACTION), NO_ACTION, stroke)
paint = make_scope(make_verify(SCOPE_ACTION), NO_ACTION, fill)



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
    Attribute("Paper", RANK_BOOTSTRAP,
              vcat([(c, a) -> c.context = X.CairoContext(X.CairoRGBSurface(nx, ny)),
                    ctx(c -> set_background(c, nx, ny, bg)),
                    ctx(c -> set_coords(c, nx, ny, border, centred))],
                   # default foreground and pen
                   Ink().before,
                   Pen().before),
              [(c, a) -> c.context = NullableContext()])
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

PAPER_SIZES = Dict("a0" => [841, 1189],
                   "a1" => [594, 841],
                   "a2" => [420, 594],
                   "a3" => [297, 420],
                   "a4" => [210, 297],
                   "a5" => [148, 210],
                   "a6" => [105, 148],
                   "a7" => [74, 105],
                   "a8" => [52, 74],
                   "a9" => [37, 52],
                   "a10" => [26, 37],
                   "letter" => [216, 279],
                   "legal" => [216, 356],
                   "junior" => [127, 203],
                   "ledger" => [279, 432])
                   

# these should be as portrait, in mm (x, y)
function paper_size(size::AbstractString)
    s = lowercase(size)
    if haskey(PAPER_SIZES, s)
        PAPER_SIZES[s]
    else
        throw(DrawingError("Unknown paper size: $(size)"))
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

function File(path::AbstractString)
    Attribute("File", RANK_OUTPUT, NO_ACTIONS,
          [ctx(c -> X.write_to_png(c.surface, path))])
end



# --- source attributes

function Ink(foreground)
    f = parse_color(foreground)
    Attribute("Ink", RANK_STATE, [ctx(c -> X.set_source(c, f))], NO_ACTIONS)
end

RED = parse_color("red")
GREEN = parse_color("green")
BLUE = parse_color("blue")
WHITE = parse_color("white")
BLACK = parse_color("black")

Ink() = Ink(BLACK) 



# --- stroke attributes

Pen(width) = Attribute("Pen", RANK_STATE, [ctx(c -> set_width(c, width))], NO_ACTIONS)

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

Scale(k) = Attribute("Scale", RANK_STATE, [ctx(c -> X.scale(c, k, k))], NO_ACTIONS)
Scale(x, y) = Attribute("Scale", RANK_STATE, [ctx(c -> X.scale(c, x, y))], NO_ACTIONS)
Translate(x, y) = Attribute("Translate", RANK_STATE, [ctx(c -> X.translate(c, x, y))], NO_ACTIONS)
Rotate(d) = Attribute("Rotate", RANK_STATE, [ctx(c -> X.rotate(c, d))], NO_ACTIONS)



# --- paths

macro lift(new, old)
    :($(esc(new))(args...) = $(esc(old))(current_context(), args...))
end

@lift(move, X.move_to)
@lift(line, X.line_to)

end

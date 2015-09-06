
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
# - other output formats
# - fancy sources
# - text
# - curves
# - actions that take lists of points (or generators?)


# --- global / thread-local state

# this is tracked via the stage variable
typealias Context Union(Void, Function, X.CairoContext)

const SCOPE_NONE = 0
const SCOPE_WITH = 1
const SCOPE_ACTION = 2

const STAGE_VOID = 0     # context uninitialized (void)
const STAGE_OUTPUT = 1   # context has (nx, ny) tuple / attribute that does so
const STAGE_PAPER = 2    # context created / attribute that does so
const STAGE_STATE = 3    # attribute that changes state

# this needs to be in a thread local variable once such things exist in julia
type ThreadContext
    context::Context
    stage::Int           # used to track context creation
    scope::Vector{Int}   # used to track scoping rules
    ThreadContext() = new(nothing, STAGE_VOID, Int[SCOPE_NONE])
end

const thread_context = ThreadContext()

function current_context()
    @assert thread_context.stage >= STAGE_PAPER "Context not initialized"
    thread_context.context
end



# --- scoping infrastructure

# before and after are functions of (ThreadContext, Attribute) -> nothing
type Attribute
    name::AbstractString
    stage::Int
    before::Vector{Function}
    after::Vector{Function}
    Attribute(name, stage, before, after) = new(name, stage, before, after)
end

const NO_ACTIONS = Function[]
NO_ACTION = c -> nothing
ctx(f) = (c, a) -> f(c.context)

function make_scope(verify, before, after)

    function scope(f, attributes::Attribute...)

        c = thread_context
        saved = false
        pushed = false

        try

            # stable sort, respecting user where possible
            a = sort!([attributes...], by=a -> a.stage, alg=InsertionSort)
                
            # save context if it exists
            if c.stage >= STAGE_PAPER
                X.save(c.context)
                saved = true
            end
            
            # check for conflicts and push scope
            verify(c, a)
            pushed = true
            
            for attribute in a
                @assert attribute.stage-1 <= c.stage <= attribute.stage 
                "Incorrect attribute order (missing output or paper attribute?)"
                for x in attribute.before
                    x(c, attribute)
                end
                c.stage = attribute.stage
                # or save as soon as we have a context
                if !saved && c.stage >= STAGE_PAPER
                    X.save(c.context)
                    saved = true
                end
            end
            
            before(c.context)
            
            f()
            
            after(c.context)
            
            for attribute in reverse(a)
                for x in attribute.after
                    x(c, attribute)
                end
            end
            
        finally

            pushed && pop!(c.scope)
            if c.scope[end] == SCOPE_NONE
                c.context = nothing
                c.stage = STAGE_VOID
            else
                saved && X.restore(c.context)
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

function verify_nesting(c, a)
    if c.scope[end] == SCOPE_ACTION 
        throw(DrawingError("Cannot nest a scope inside an action scope"))
    end
end

function make_verify(scope)
    function verify(c, a)
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

function make_parser(name, table)
    function parser(value)
        v = lowercase(value)
        if haskey(table, v)
            table[v]
        else
            throw(DrawingError("Unknown $(name): $(value)"))
        end
    end
end

function make_int_parser(name, table)
    string_parser = make_parser(name, table)
    function parser(value)
        if isa(value, Integer)
            value
        elseif isa(value, AbstractString)
            string_parser(value)
        else
            throw(DrawingError("Bad type for $(name): $(typeof(value))"))
        end
    end
end



# --- output (file, display, etc)

function File(path::AbstractString)
    Attribute("File", STAGE_OUTPUT,
              [(c, a) -> c.context = (nx, ny) -> X.CairoRGBSurface(nx, ny)],
              [ctx(c -> X.write_to_png(c.surface, path))])
end



# --- paper declaration

const LANDSCAPE = 1
const PORTRAIT = 2

const ORIENTATIONS = Dict("landscape" => LANDSCAPE,
                          "porttrait" => PORTRAIT)
parse_orientation = make_int_parser("orientation", ORIENTATIONS)

# it's OK (necessary, even) for this to have non-null defaults, because it's
# setting up a completely new context (unlike other scopes, which are simply
# modifying some part).

function Paper(nx::Int, ny::Int; background="white", border=0.1::Float64,
               centred=false::Bool)
    bg = parse_color(background)
    Attribute("Paper", STAGE_PAPER,
              vcat([(c, a) -> c.context = X.CairoContext(c.context(nx, ny)),
                    ctx(c -> set_background(c, nx, ny, bg)),
                    ctx(c -> set_coords(c, nx, ny, border, centred))],
                   # default foreground and pen
                   Ink(BLACK).before,
                   Pen(0.02; cap=X.CAIRO_LINE_CAP_ROUND, join=X.CAIRO_LINE_JOIN_ROUND).before),
              NO_ACTIONS)
end

function Paper(size::AbstractString; dpi=300::Int, background="white", 
               orientation=LANDSCAPE, border=0.1::Float64,
               centred=false::Bool)
    nx, ny = map(int, dpi * parse_paper_size(size) / 25.4)
    if parse_orientation(orientation) == LANDSCAPE
        nx, ny = ny, nx
    end
    Paper(nx, ny; background=background, border=border, centred=centred)
end

# these should be as portrait, in mm (x, y)
const PAPER_SIZES = Dict("a0" => [841, 1189],
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
                         
parse_paper_size = make_parser("paper size", PAPER_SIZES)                   

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



# --- source attributes

function Ink(foreground)
    f = parse_color(foreground)
    Attribute("Ink", STAGE_STATE, [ctx(c -> X.set_source(c, f))], NO_ACTIONS)
end

RED = parse_color("red")
GREEN = parse_color("green")
BLUE = parse_color("blue")
WHITE = parse_color("white")
BLACK = parse_color("black")



# --- stroke attributes

const LINE_CAPS = Dict("butt" => X.CAIRO_LINE_CAP_BUTT,
                       "round" => X.CAIRO_LINE_CAP_ROUND,
                       "square" => X.CAIRO_LINE_CAP_SQUARE)
parse_line_cap = make_int_parser("line cap", LINE_CAPS)

LINE_JOINS = Dict("mitre" => X.CAIRO_LINE_JOIN_MITER,
                  "miter" => X.CAIRO_LINE_JOIN_MITER,
                  "round" => X.CAIRO_LINE_JOIN_ROUND,
                  "bevel" => X.CAIRO_LINE_JOIN_BEVEL)
parse_line_join = make_int_parser("line join", LINE_JOINS)

function Pen(width; cap=nothing, join=nothing)
    Attribute("Pen", STAGE_STATE, 
              vcat(width >= 0 ? [ctx(c -> set_width(c, width))] : [],
                   cap != nothing ? [ctx(c -> X.set_line_cap(c, parse_line_cap(cap)))] : [],
                   join != nothing ? [ctx(c -> X.set_line_join(c, parse_line_join(join)))] : []),
              NO_ACTIONS)
end

Pen(; cap=X.CAIRO_LINE_CAP_ROUND, join=X.CAIRO_LINE_JOIN_ROUND) = Pen(-1; cap=cap, join=join)

function set_width(c, width)
    # width is in user coords, so scale to device coords
    v = [width, width]
    X.user_to_device_distance!(c, v)
    v = map(abs, v)
    X.set_line_width(c, sum(v)/2)
end



# --- transforms

Scale(k) = Attribute("Scale", STAGE_STATE, [ctx(c -> X.scale(c, k, k))], NO_ACTIONS)
Scale(x, y) = Attribute("Scale", STAGE_STATE, [ctx(c -> X.scale(c, x, y))], NO_ACTIONS)
Translate(x, y) = Attribute("Translate", STAGE_STATE, [ctx(c -> X.translate(c, x, y))], NO_ACTIONS)
Rotate(d) = Attribute("Rotate", STAGE_STATE, [ctx(c -> X.rotate(c, d))], NO_ACTIONS)



# --- paths

macro lift(new, old)
    :($(esc(new))(args...) = $(esc(old))(current_context(), args...))
end

@lift(move, X.move_to)
@lift(line, X.line_to)

end

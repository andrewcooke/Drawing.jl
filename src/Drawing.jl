
module Drawing

import Cairo; const X = Cairo
import Graphics; const G = Graphics
import Colors; const C = Colors
import Tk; const T = Tk

export DrawingError, has_current_point, get_current_point, 
       current_context,
       with, draw, paint,
       cm, mm, in, pts,
       PNG, PDF, TK, Paper, Axes, Pen, Ink, Scale, Translate, Rotate,
       move, line

include("cairo.jl")

type DrawingError <: Exception 
    msg::AbstractString
end
Base.showerror(io::IO, e::DrawingError) = print(io, e.msg)

# TODO
# - gtk/tk window
# - fancy sources
# - text
# - curves
# - actions that take lists of points (or generators?)


# --- global / thread-local state

# this is tracked via the stage variable
typealias Context Nullable{X.CairoContext}

const SCOPE_NONE = 0
const SCOPE_WITH = 1
const SCOPE_ACTION = 2

const STAGE_NONE = 0     # context uninitialized
const STAGE_OUTPUT = 1   # create context (and on exit save file)
const STAGE_PAPER = 2    # background colour
const STAGE_AXES = 3     # axis scaling
const STAGE_DRAW = 4     # general drawing

# this needs to be in a thread local variable once such things exist in julia
type ThreadContext
    context::Context
    stage::Int           # used to track context creation
    scope::Vector{Int}   # used to track scoping rules
    ThreadContext() = new(Context(), STAGE_NONE, Int[SCOPE_NONE])
end

const thread_context = ThreadContext()
current_context() = get(thread_context.context)



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
ctx(f) = (c, a) -> f(get(c.context))

function save_once(ctx, saved)
    # save context if it exists
    if !saved && ctx.stage > STAGE_NONE
        X.save(get(ctx.context))
        true
    else
        saved
    end
end

function add_defaults(stage, attributes)
    i = 1
    while i <= length(attributes) && stage <= attributes[end].stage
        if attributes[i].stage == stage
            stage += 1
            i += 1
        elseif attributes[i].stage > stage
            splice!(attributes, i:i-1, [DEFAULT_ATTRIBUTES[stage]])
            stage += 1
        else
            i += 1
        end
    end
    while stage < STAGE_DRAW
        push!(attributes, DEFAULT_ATTRIBUTES[stage])
        stage += 1
    end
end

function make_scope(verify_push, before, after)

    function scope(f, attributes::Attribute...)

        c = thread_context
        saved = false
        pushed = false

        try

            saved = save_once(c, saved)

            # stable sort, respecting user where possible
            a = sort!([attributes...], by=a -> a.stage, alg=InsertionSort)
            add_defaults(c.stage+1, a)
                
            # check for conflicts and push scope
            verify_push(c, a)
            pushed = true
            
            for attribute in a

                if min(c.stage+1, STAGE_DRAW) != attribute.stage 
                    throw(DrawingError("Initialization attributes must be in outermost scope."))
                end

                for x in attribute.before
                    x(c, attribute)
                end
                c.stage = attribute.stage
                saved = save_once(c, saved)
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

            pushed && pop!(c.scope)
            
            if c.scope[end] == SCOPE_NONE
                c.context = Context()
                c.stage = STAGE_NONE
            else
                saved && X.restore(get(c.context))
            end
            
        end
    end
end


# --- actual scopes

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

# allow sizes to be given as 30cm etc
const cm = 10
const mm = 1
const in = 25.4
const pts = in/72

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

const LANDSCAPE = 1
const PORTRAIT = 2
const ORIENTATIONS = Dict("landscape" => LANDSCAPE,
                          "porttrait" => PORTRAIT)
parse_orientation = make_int_parser("orientation", ORIENTATIONS)

# set these at the start so thing look pretty
function with_defaults(before)
    vcat(before, Pen(join="round", cap="round").before)
end

# width and heigh are in mm
function PDF(path, width_mm, height_mm)
    Attribute("PDF", STAGE_OUTPUT,
              with_defaults([(c, a) -> c.context = X.CairoContext(X.CairoPDFSurface("formats.pdf", width_mm/pts, height_mm/pts))]),
              [ctx(c -> X.destroy(c))])
end

function PDF(path; size="a4", orientation=LANDSCAPE)
    w, h = parse_paper_size(size)
    w, h = parse_orientation(orientation) == LANDSCAPE ? (h, w) : (w, h)
    PDF(path, w, h)
end

function PNG(path, width_px, height_px)
    Attribute("PNG", STAGE_OUTPUT,
              with_defaults([(c, a) -> c.context = X.CairoContext(X.CairoRGBSurface(width_px, height_px))]),
              [ctx(c -> X.write_to_png(c.surface, path)),
               ctx(c -> X.destroy(c))])
end

function press_return()
    println("Press RETURN to close window")
    readline(STDIN)
end

function TK(width_px, height_px; name="Drawing", pause=true)
    window, canvas = nothing, nothing
    function create(c, a)
        window = Tk.Toplevel(name, width_px, height_px)
        canvas = Tk.Canvas(window)
        Tk.pack(canvas, expand=true, fill="both")
        c.context = Tk.getgc(canvas)
    end
    function destroy(c, a)
        Tk.reveal(canvas)
        Tk.update()
        if pause
            press_return()
            Tk.destroy(window)
        end
    end
    Attribute("TK", STAGE_OUTPUT,
              with_defaults([create]),
              [destroy])
end



# --- paper (background colour)

RED = parse_color("red")
GREEN = parse_color("green")
BLUE = parse_color("blue")
WHITE = parse_color("white")
BLACK = parse_color("black")

function Paper(background="white")
    bg = parse_color(background)
    Attribute("Paper", STAGE_PAPER,
              [ctx(c -> set_background(c, bg))],
              NO_ACTIONS)
end

function set_background(c, bg)
    X.save(c)
    X.rectangle(c, 0, 0, X.width(c.surface), X.height(c.surface))
    X.set_source(c, bg)
    X.fill(c)
    X.restore(c)
end



# --- axes (coordinate scaling)

function Axes(; scale=1, border=0.1, centred=false)
    Attribute("Axes", STAGE_AXES,
              [ctx(c -> set_coords(c, scale, border, centred)),
               # start at origin
               ctx(c -> X.move_to(c, 0, 0))],
              NO_ACTIONS)
end

function set_coords(c, scale, border, centred)
    nx, ny = X.width(c.surface), X.height(c.surface)
    if centred
        d = scale / (1 - 2*border)
        b = (d - scale) / scale
        if nx < ny  # portrait
            G.set_coords(c, 0, 0, nx, ny, -scale-b, scale+b, scale*(ny/nx)+b, -scale*(ny/nx)-b)
        else
            G.set_coords(c, 0, 0, nx, ny, -scale*(nx/ny)-b, scale*(nx/ny)+b, scale+b, -scale-b)
        end
    else
        d = scale / (1 - 2*border)
        b = (d - scale) / 2
        if nx < ny  # portrait
            G.set_coords(c, 0, 0, nx, ny, -b, scale+b, scale*(ny/nx)*d - b, -b)
        else
            G.set_coords(c, 0, 0, nx, ny, -b, scale*(nx/ny)*d - b, scale+b, -b)
        end
    end
end



# --- source/stroke attributes

function Ink(foreground)
    f = parse_color(foreground)
    Attribute("Ink", STAGE_DRAW, [ctx(c -> X.set_source(c, f))], NO_ACTIONS)
end

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
    Attribute("Pen", STAGE_DRAW, 
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

Scale(k) = Attribute("Scale", STAGE_DRAW, [ctx(c -> X.scale(c, k, k))], NO_ACTIONS)
Scale(x, y) = Attribute("Scale", STAGE_DRAW, [ctx(c -> X.scale(c, x, y))], NO_ACTIONS)
Translate(x, y) = Attribute("Translate", STAGE_DRAW, [ctx(c -> X.translate(c, x, y))], NO_ACTIONS)
Rotate(d) = Attribute("Rotate", STAGE_DRAW, [ctx(c -> X.rotate(c, d))], NO_ACTIONS)



# --- paths

macro lift(new, old)
    :($(esc(new))(args...) = $(esc(old))(current_context(), args...))
end

@lift(move, X.move_to)
@lift(line, X.line_to)



# --- defaults duing startup (working through the stages)

DEFAULT_ATTRIBUTES = Dict(STAGE_OUTPUT => TK(300, 200),
                          STAGE_PAPER => Paper(WHITE),
                          STAGE_AXES => Axes(),)

end

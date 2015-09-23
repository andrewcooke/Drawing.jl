
# TODO
# - transparency
# - fancy sources
# - text layout attributes
# - ellipses, bezier curves or similar
# - actions that take lists of points (or generators?)
# - other shapes
# - align consistent
# - asymmetric scaling of text?
# - rotation only as a keyword arg for shapes?
# - axes shifting separate from scale / shift?

module Drawing

import Cairo; const X = Cairo
import Graphics; const G = Graphics
import Colors; const C = Colors
import Tk; const T = Tk

export DrawingError,
       current_context,
       with, cairo, draw, paint,
       cm, mm, in, pts, rad, deg,
       PNG, PDF, TK, Paper, Axes, Pen, Ink, Scale, Translate, Rotate, Font,
       move, line, circle, text, rectangle, square,
       print_fonts

# add additional calls to cairo
include("cairo.jl")



# --- utilities

type DrawingError <: Exception 
    msg::AbstractString
end
Base.showerror(io::IO, e::DrawingError) = print(io, e.msg)

# allow sizes to be given as 30cm etc (convert to mm)
const cm = 10
const mm = 1
const in = 25.4
const pts = in/72

# similarly for angles (convert to degrees)
const rad = 180/pi
const deg = 1
deg2rad(x) = x*pi/180

int(x) = round(Int, x)

# lookup value from table, using lower case string as key
function lookup(name, table, value::AbstractString)
    v = lowercase(value)
    if haskey(table, v)
        table[v]
    else
        throw(DrawingError("Unknown $(name): $(value)"))
    end
end

parse_color(c::AbstractString) = parse(C.Colorant, c)
parse_color(c::C.Color) = c

const RED = parse_color("red")
const GREEN = parse_color("green")
const BLUE = parse_color("blue")
const WHITE = parse_color("white")
const BLACK = parse_color("black")



# --- global / thread-local state

# this is tracked via the stage variable
typealias Context Nullable{X.CairoContext}

const SCOPE_NONE = 0
const SCOPE_INNER = 1
const SCOPE_OUTER_DRAW = 2
const SCOPE_OUTER_PAINT = 3
const SCOPE_OUTER_OTHER = 3

const STAGE_NONE = 0     # context uninitialized
const STAGE_OUTPUT = 1   # create context (and on exit save file)
const STAGE_PAPER = 2    # background colour
const STAGE_AXES = 3     # axis scaling
const STAGE_DRAW = 4     # general drawing

type FontState
    fd::FontDescription
    align::Int
    size::Float64        # not applied directly as transform dependent
    FontState() = new("sans", 1, -1)
    FontState(f::FontState) = new(copy(f.fd), f.align, f.size)
end


# this needs to be in a thread local variable once such things exist in julia
type ThreadContext
    context::Context
    font::Vector{FontState}  # separate from context
    stage::Int           # used to track context creation
    scope::Vector{Int}   # used to track scoping rules
    ThreadContext() = new(Context(), FontState[FontState()], STAGE_NONE, Int[SCOPE_NONE])
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

function make_scope(verify, before, after)

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
            scope = verify(c, a)
            push!(c.scope, scope)
            push!(c.font, FontState(c.font[end]))
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

            args = before(get(c.context))
            
            args == nothing ? f() : f(args...)
            
            after(get(c.context))
            
            for attribute in reverse(a)
                for x in attribute.after
                    x(c, attribute)
                end
            end
            
        finally

            if pushed
                pop!(c.scope)
                pop!(c.font)
            end
            
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

function preserve_current_point(action)
    function (c)
        has_point = has_current_point(c)
        x, y = get_current_point(c)
        action(c)
        if has_point
            X.move_to(c, x, y)
        end
    end
end    

stroke = preserve_current_point(X.stroke)
fill = preserve_current_point(X.fill)

function make_verify(scope)
    function verify(c, a)
        if c.scope[end] > SCOPE_INNER
            throw(DrawingError("Cannot nest a scope inside an action scope"))
        end
        scope
    end
end

INACTIVE = c -> nothing
with = make_scope(make_verify(SCOPE_INNER), INACTIVE, INACTIVE)
cairo = make_scope(make_verify(SCOPE_OUTER_OTHER), c -> [c], INACTIVE)
draw = make_scope(make_verify(SCOPE_OUTER_DRAW), INACTIVE, stroke)
paint = make_scope(make_verify(SCOPE_OUTER_PAINT), INACTIVE, fill)


# --- output (file, display, etc)

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
parse_paper_size(size::AbstractString) = lookup("paper size", PAPER_SIZES, size)

const LANDSCAPE = 1
const PORTRAIT = 2
const ORIENTATIONS = Dict("landscape" => LANDSCAPE,
                          "porttrait" => PORTRAIT)
parse_orientation(orientation::AbstractString) = lookup("orientation", ORIENTATIONS, orientation)
parse_orientation(orientation::Integer) = orientation

# set these at the start so thing look pretty
function with_defaults(before)
    vcat(before, 
         Pen(join="round", cap="round").before,
         Font("sans").before)
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

function TK(width_px, height_px; name="Drawing", destroy=true)
    window, canvas = nothing, nothing
    function create(c, a)
        window = Tk.Toplevel(name, width_px, height_px)
        canvas = Tk.Canvas(window)
        Tk.pack(canvas, expand=true, fill="both")
        c.context = Tk.getgc(canvas)
    end
    function close(c, a)
        Tk.reveal(canvas)
        Tk.update()
        if destroy
            press_return()
            Tk.destroy(window)
        end
    end
    Attribute("TK", STAGE_OUTPUT,
              with_defaults([create]),
              [close])
end



# --- paper (background colour)

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
    portrait = nx < ny
    sm, lg = portrait ? (nx, ny) : (ny, nx)
    b = border * sm
    u = sm - 2 * b

    # if portrait, and nx = 10, scale = 2, border = 0.1, then we have
    # a border b = 1, used u = 8
    if centred
        # so x is -2.5 to 2.5
        G.set_coords(c, 0, 0, nx, ny, 
                     -scale * nx / u, scale * nx / u,
                     scale * ny / u, -scale * ny / u)
    else
        G.set_coords(c, 0, 0, nx, ny,
                     -scale * b / u, scale * (nx - b) / u,
                     scale * (ny - b) / u, -scale * b / u)
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
parse_line_cap(cap::AbstractString) = lookup("line cap", LINE_CAPS, cap)
parse_Line_cap(cap::Integer) = cap

const LINE_JOINS = Dict("mitre" => X.CAIRO_LINE_JOIN_MITER,
                        "miter" => X.CAIRO_LINE_JOIN_MITER,
                        "round" => X.CAIRO_LINE_JOIN_ROUND,
                        "bevel" => X.CAIRO_LINE_JOIN_BEVEL)
parse_line_join(join::AbstractString) = lookup("line join", LINE_JOINS, join)
parse_line_join(join::Integer) = join

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

# we only support (global!) conformal mapping - not general affine
# transoforms.  this means that we can describe everything as a scale,
# rotation and translation.  assuming that makes, for example, text
# handling much simpler.

Scale(factor) = Attribute("Scale", STAGE_DRAW, [ctx(c -> X.scale(c, factor, factor))], NO_ACTIONS)
Translate(x, y) = Attribute("Translate", STAGE_DRAW, [ctx(c -> X.translate(c, x, y))], NO_ACTIONS)
Rotate(degree) = Attribute("Rotate", STAGE_DRAW, [ctx(c -> X.rotate(c, deg2rad(degree)))], NO_ACTIONS)

function describe_transform(c)
    zero = X.device_to_user(c, 0, 0)
    one = X.device_to_user(c, 1, 1)
    dx, dy = one[1] - zero[1], one[2] - zero[2]
    # weird sign below because reflected in y
    rotation = pi/4 - atan2(-dy, dx)
    scale = sqrt(dx*dx + dy*dy) / sqrt(2)
    translation = zero
    translation, scale, rotation
end



# --- (pango) text attributes

function to_font(fd::FontDescription)
    s = string(fd)
    "Font(\"$s\")"
end

function print_fonts()
    fm = get_font_map_default()
    ff = list_families(fm)
    sort!(ff, by=(f-> get_name(f)))
    for f in ff
        m = is_monospace(f) ? "[monospace]" : ""
        println("\n  $(get_name(f)) $m")
        fc = list_faces(f)
        for c in fc
            d = describe(c)
            @printf("  %20s %s\n", "$(get_name(c)):", to_font(d))
        end
    end
end

const STYLES = Dict("normal" => PANGO_STYLE_NORMAL,
                    "italic" => PANGO_STYLE_ITALIC,
                    "oblique" => PANGO_STYLE_OBLIQUE)
parse_style(style::AbstractString) = lookup("font style", STYLES, style)
parse_style(style::Integer) = style

const VARIANTS = Dict("normal" => PANGO_VARIANT_NORMAL,
                      "smallcaps" => PANGO_VARIANT_SMALL_CAPS)
parse_variant(variant::AbstractString) = lookup("font variant", VARIANTS, variant)
parse_variant(variant::Integer) = variant

const WEIGHTS = Dict("ultralight" => PANGO_WEIGHT_ULTRALIGHT,
                     "light" => PANGO_WEIGHT_LIGHT,
                     "normal" => PANGO_WEIGHT_NORMAL,
                     "bold" => PANGO_WEIGHT_BOLD,
                     "ultrabold" => PANGO_WEIGHT_ULTRABOLD,
                     "heavy" => PANGO_WEIGHT_HEAVY)
parse_weight(weight::AbstractString) = lookup("font weight", WEIGHTS, weight)
parse_weight(weight::Integer) = weight

const STRETCHES = Dict("ultracondensed" => PANGO_STRETCH_ULTRA_CONDENSED,
                       "extracondensed" => PANGO_STRETCH_EXTRA_CONDENSED,
                       "condensed" => PANGO_STRETCH_CONDENSED,
                       "semicondensed" => PANGO_STRETCH_SEMI_CONDENSED,
                       "normal" => PANGO_STRETCH_NORMAL,
                       "semiexpanded" => PANGO_STRETCH_SEMI_EXPANDED,
                       "expanded" => PANGO_STRETCH_EXPANDED,
                       "extraexpanded" => PANGO_STRETCH_EXTRA_EXPANDED,
                       "ultraexpanded" => PANGO_STRETCH_ULTRA_EXPANDED)
parse_stretch(stretch::AbstractString) = lookup("font stretch", STRETCHES, stretch)
parse_stretch(stretch::Integer) = stretch

const GRAVITY = Dict("auto" => PANGO_GRAVITY_AUTO,
                     "north" => PANGO_GRAVITY_NORTH,
                     "east" => PANGO_GRAVITY_EAST,
                     "south" => PANGO_GRAVITY_SOUTH,
                     "west" => PANGO_GRAVITY_WEST)
parse_gravity(gravity::AbstractString) = lookup("font gravity", GRAVITY, gravity)
parse_gravity(gravity::Integer) = gravity

set_via(setter, value) = (c, a) -> setter(c.font[end].fd, value)

function Font(desc; size=nothing, style=nothing, variant=nothing, weight=nothing, stretch=nothing, gravity=nothing)
    Attribute("Font", STAGE_DRAW,
              vcat(desc != nothing ? [(c, a) -> c.font[end].fd = desc] : [],
                   size != nothing ? [(c, a) -> c.font[end].size = size] : [],
                   style != nothing ? [set_via(set_style, parse_style(style))] : [],
                   variant != nothing ? [set_via(set_variant, parse_variant(variant))] : [],
                   weight != nothing ? [set_via(set_weight, parse_weight(weight))] : [],
                   stretch != nothing ? [set_via(set_stretch, parse_stretch(stretch))] : [],
                   gravity != nothing ? [set_via(set_gravity, parse_gravity(gravity))] : []),
              NO_ACTIONS)
end

Font(; size=nothing, style=nothing, variant=nothing, weight=nothing, stretch=nothing, gravity=nothing) = Font(nothing; size=size, style=style, weight=weight, stretch=stretch, gravity=gravity)



# --- paths

macro lift(new, old)
    :($(esc(new))(args...) = $(esc(old))(current_context(), args...))
end

@lift(move, X.move_to)
@lift(line, X.line_to)

function circle(radius; from=0, to=360)
    c = current_context()
    x, y = get_current_point(c)
    X.new_sub_path(c)
    X.arc(c, x, y, radius, deg2rad(from), deg2rad(to))
    X.move_to(c, x, y)  # don't change current point
end

# if (x, y) is the bottom left point of the box, then this returns an
# (x,y) that should be the new bottom-left point, such that the box
# appears aligned correctly relative to the given point(!)
# to make things more exciting, height should be negated when using the
# 'y goes down' convention (ie from pango), and then everything is 
# relative to top left.
function alignment(x, y, align, width, height)
    xalign = x - ((align - 1) % 3) * width / 2
    if height > 0
        yalign = y - height + round((align - 2) / 3) * height / 2
    else
        yalign = y + round((align - 2) / 3) * height / 2
    end
    xalign, yalign
end

function text(s; align=1)

    t = thread_context
    f = t.font[end]
    c = get(t.context)
    l = Layout(c.layout)    # our pango routines use wrapper
    tr, sc, rt = describe_transform(c)

    # todo - maybe provide a flag to skip this transform and let the
    # user suffer whatever self-inflicted pain they want?
    X.save(c)
    X.reset_transform(c)
    X.rotate(c, rt)
    x, y = get_current_point(c)

    try
        
        update_layout(c, l)
        if f.size > 0
            set_absolute_size(f.fd, f.size / sc)
        end
        set_description(l, f.fd)

        set_text(l, s)

        ink, log = get_pixel_extents(l)
        # -height because y axis is inverted
        X.move_to(c, alignment(x-log.x, y-log.y, align, log.width, -log.height)...)

        show_path(c, l)

    finally
        X.move_to(c, x, y)
        X.restore(c)
    end
end

function rectangle(width, height; align=1)
    c = current_context()
    x, y = get_current_point(c)
    try
        a, b = alignment(x, y, align, width, height)
        X.move_to(c, a, b)
        X.line_to(c, a+width, b)
        X.line_to(c, a+width, b+height)
        X.line_to(c, a, b+height)
        X.line_to(c, a, b)
    finally
        X.move_to(c, x, y)
    end
end

function square(side; align=1)
    rectangle(side, side; align=align)
end

# --- defaults during startup (working through the stages)

DEFAULT_ATTRIBUTES = Dict(STAGE_OUTPUT => TK(300, 200),
                          STAGE_PAPER => Paper(WHITE),
                          STAGE_AXES => Axes(),)

end

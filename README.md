[![Build Status](https://travis-ci.org/andrewcooke/Drawing.jl.svg?branch=master)](https://travis-ci.org/andrewcooke/Drawing.jl)

# Drawing

* [Introduction](#introduction)
* [Getting Started](#getting-started)
* [API](#api)
  * [Scopes](#scopes)
  * [Attributes](#attributes)
  * [Actions](#actions)
  * [Raw Cairo](#raw-cairo)

# Introduction

A library for easy, extensible, drawing (diagrams, lines, shapes).

In other words: simple, imperative vector graphics; a wrapper around Cairo;
an interface similar to Processing.  For a declarative approach, see
[Compose.jl](https://github.com/dcjones/Compose.jl).  For more control and
complexity, use [Cairo.jl](https://github.com/JuliaLang/Cairo.jl) directly.

In providing a simple API, the package has two important aims:

1. Changes to the graphics context are *scoped*.  This is implemented via "do
   blocks".

2. Changes are *nested and composable*.  So, for example, you can define a
   context with certain attributes (ink colour, pen width, etc), and then have
   an inner scope that changes a subset of those values.

# Getting Started

```julia
julia> Pkg.add("Drawing")

julia> using Drawing

julia> with(Axes(centred=true), Pen(0.2)) do
		   paint(Ink("yellow")) do
			   circle(1)           # face background, painted yellow
		   end
		   draw() do
			   circle(1)           # face outline, drawn black (default)
			   circle(0.5; from=200deg, to=340deg)    # smile
		   end
		   paint() do
			   move(0.3, 0.25)     # right eye position
			   circle(0.2)         # paint eye
			   move(-0.3, 0.25)    # left eye position
			   circle(0.2)         # paint eye
		   end
	   end
Press RETURN to close window
```

which displays this window:

![screenshot](screenshot.png)

# API

The API consists of:

1. **Scopes** introduce *attributes*, may include either nested *scopes* or
   *actions*, and may trigger some process (like stroking or filling a path)
   at the end.  For example, `draw()` is a scope that introduces attributes,
   includes actions, and draws the path on closing.

2. **Attributes** modify the Cairo context for the duration of the scope.  For
   example, `Ink()` sets the Cairo source for the scope.

3. **Actions** typically describe a Cairo path.  For example, `move()` and
   `line()`.

These can be seen in the example below, which has three scopes, nested two
deep, and includes the attributes `Ink()`, `Pen()`, etc.

```julia
with(PNG("red-blue-square.png", 100, 100), Ink("red"), Pen(0.1)) do
    draw(Ink("blue")) do
        move(0, 0)
        line(1, 0)
        line(1, 1)
    end
	draw() do  # the Ink is red here - the scope above has closed
		line(0, 1)
        line(0, 0)
	end
end
```

[<img align="left" src="test/target/red-blue-square.png"/>](test/red-blue-square.jl)

The default coordinate system is from 0 to 1 (on the shorter axis, origin
bottom left), with 10% of the space used as a border on each side.  Unlike
"raw" cairo, the "current point" is preserved across strokes.

## Scopes

* `with()` defines a scope, but takes no action on closing.

* `draw()` defines a scope and, on closing, draws the current path.

* `paint()` defines a scope and, on closing, fills the current path.

There are some constraints on how scopes are used: the `with()` scope cannot
contain actions; the `draw()` and `paint()` scopes cannot contain nested
scopes.

## Attributes

There are two kinds of attribute: initial and dynamic.

The order of initial attributes is not important, but they can only appear in
the outermost scope.  The order of dynamic attributes may be important (eg the
relative order of `Scale()` and `Translate()`) and follows the order given in
the scope, from left to right.

### Initial Attributes

* `PNG(path, width_px, height_px)` initializes a Cairo context and, at the end
  of the scope, writes a PNG format image, of the given size, to the given
  path.  Here width and height are measured in *pixels*.

* `PDF(path, width_mm, height_mm)` initializes a Cairo context and, at the end
  of the scope, writes a PDF format image, of the given size, to the given
  path.  Here width and height are measured in *mm*.

* `PDF(path; size="a4", orientation="landscape")` initializes a Cairo context
  and, at the end of the scope, writes a PDF format image, of the given size,
  to the given path.

* `TK(width_px, height_px; name="Drawing", destroy=true)` initializes a Cairo
  context associated with a Tk window, which is displayed at the end of the
  scope.  If `destroy=true` then the user is asked to press return, after which
  the window is destroyed; if it is false then there is no prompt and the
  window remains on the screen (until the window is closed by the user or
  julia exits).

* `Paper(background)` sets the background colour.

* `Axes(; scale=1, border=0.1, centred=false)` Sets the Cairo user
  coordinates.  Excluding the border (measured as a fraction of the smallest
  side), the coordinate system is either bottom left, or centred, and is
  scaled uniformly (assuming square pixels), so that the smallest axis has
  unit length.

  Below are plotted unit axes (x is horizontal) for 100x140 pixel images, with
  a border of 0.1 (ie 10 pixels), where the landscape axes are centred.  Note
  that drawing is not clipped to the unit axes area - it can extend over the
  whole page.

  [![portrait](test/target/portrait.png)](test/portrait.jl)
  [![landscape, centred](test/target/centred-landscape.png)](test/centred-landscape.jl)

  *Click on image to see associated script.*

### Dynamic Attributes

* `Ink(colour)` sets the Cairo source (ie the colour used to draw or paint).
  The colour can be a `Color` (see the Colors.jl package) or string ("red",
  "blue", etc).

* `Pen(width; cap=..., join=...)` sets the Cairo stroke properties (cap and
  join can be strings or constants from the Cairo.jl package).  Omitted values
  are unchanged.

  **Note:** pen width is in user units, but does not change if `Scale()` is
  used *afterwards*.

* `Pen(; cap=..., join=...)` as above, but allows width to be omitted (in
  which case the previous value is used).

  Below, example lines with cap/join (from left to right) of round/round,
  butt/mitre, square/bevel.
  
  [![round/round](test/target/round-round.png)](test/round-round.jl)
  [![butt/mitre](test/target/butt-mitre.png)](test/butt-mitre.jl)
  [![square/bevel](test/target/square-bevel.png)](test/square-bevel.jl)

  *Click on image to see associated script.*

* `Scale(factor)` scales the Cairo user coordinates.  This is a relative
  correction - values smaller than one mean that the same shape (ie the same
  coordinates) displays a smaller result.

  **Note:** To scale the initial axes to have a range of 0-100, say, use
 `Scale(1/100)` (ie use the reciprocal of the range required).

* `Translate(x, y)` translates the Cairo user coordinates.  This is a relative
  correction - the same shape (ie the same coordinates) appear shifted by the
  given x and y offsets.

* `Rotate(angle)` rotates the Cairo user coordinates about the origin.  The
  angle is measured in degrees, anti-clockwise.

  Below, the same unit square is plotted (from left to right): in the original
  axes; after `Scale(0.5)`; after `Scale(0.5), Translate(1, 1)`; after
  `Rotate(pi/4)`.

  [![default](test/target/square.png)](test/square.jl)
  [![scale](test/target/square-scale.png)](test/square-scale.jl)
  [![scale+translate](test/target/square-scale-translate.png)](test/square-scale-translate.jl)
  [![rotate](test/target/square-rotate.png)](test/square-rotate.jl)

  *Click on image to see associated script.*

## Actions

Currently, all actions affect the Cairo path.

* `move(x, y)` moves the current point to given point in user coordinates.

* `line(x, y)` creates a straught line path between the current point and the
  given point, in user coordinates.

* `circle(radius; from=0, to=2pi)` create a circle centred at the current
  point, with a given radius.  Setting `from` and `to` to smaller angles
  creates an arc (incomplete circle).

## Raw Cairo

There is an additional scope (see above) called `cairo()` which should be
followed by a do block with a single argument, which is the cairo context.
This can then be used to make arbitrary calls to Cairo functions.

For example:

```julia
julia> using Drawing

julia> using Cairo

julia> cairo() do ctx
          line_to(ctx, 1, 1)
	      stroke(ctx)
       end
Press RETURN to close window
```

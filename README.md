[![Build Status](https://travis-ci.org/andrewcooke/Drawing.jl.svg?branch=master)](https://travis-ci.org/andrewcooke/Drawing.jl)

# Drawing

A library for drawing (diagrams, lines, shapes).

In other words: simple, imperative vector graphics; a wrapper around Cairo;
an interface similar to Processing.  For a declarative approach, see
[Compose.jl](https://github.com/dcjones/Compose.jl).  For more control and
complexity, use [Cairo.jl](https://github.com/JuliaLang/Cairo.jl) directly.

Although simple, the package has two important aims:

1. Changes to the graphics context are *scoped*.  This is implemented via "do
   blocks".

2. The changes are *nested and composable*.  So, for example, you can define a
   context with certain pen attributes (colour, width, etc), and then have an
   inner scope that changes a subset of those values.

Both of these are demonstrated in the examples below.

## Example

```julia
with(File("foo.png"), Paper(100, 100), Pen("red"; width=0.01)) do
    move(0.0, 0.0)
    line(1.0, 0.0)
	with(Pen(width=0.02)) do
		line(1.0, 1.0)
		line(0.0, 1.0)
	end
    line(0.0, 0.0)
end
```

draws a red square, on a white background, in a 100x100 pixel png format
image, with two different line widths.

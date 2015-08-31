[![Build Status](https://travis-ci.org/andrewcooke/Drawing.jl.svg?branch=master)](https://travis-ci.org/andrewcooke/Drawing.jl)

# Drawing

A library for drawing (diagrams, lines, shapes).

In more formal terms - simple, imperative vector graphics.  A wrapper around
Cairo to give an interface closer to, for example, Processing.  For a
declarative approach, see [Compose.jl](https://github.com/dcjones/Compose.jl).
For more control and complexity, see
[Cairo.jl](https://github.com/JuliaLang/Cairo.jl).

## Example

```julia
with(File("foo.png"), Paper("a4"), Pen("red")) do
    move(0.0, 0.0)
    line(1.0, 0.0)
    line(1.0, 1.0)
    line(0.0, 1.0)
    line(0.0, 0.0)
end
```

draws a red square, on a white background, A4 landscape at 300dpi.

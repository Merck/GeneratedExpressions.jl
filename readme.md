# GeneratedExpressions.jl: <br> Expression Comprehensions in Julia

<p align="center">
  <a href="#about">About</a> |
  <a href="#context-reactivedynamics">Context</a> |
  <a href="#features">Features</a> |
  <a href="#showcase">Showcase</a> |
  <a href="https://merck.github.io/GeneratedExpressions.jl/">Documentation</a>
</p>

## About

The package implements a metalanguage to support code-less expression comprehensions in Julia. 

In particular, we provide a convenient proxy (inspired by mustache.js's notation) which takes an expression (string, alternatively), interpolates the $s in the expressions from ranges provided at the input, and then amalgamates the generated expressions into a block, a tuple, etc. 

It is possible to retrieve the generated expression (function `generate`) or to evaluate the expression in the caller's scope on the fly (macro `@generate`, `@fileval`).

## Context: Dynamics of Value Evolution (DyVE)
 
The package is an integral part of the **Dynamics of Value Evolution (DyVE)** computational framework for learning, designing, integrating, simulating, and optimizing R&D process models, to better inform strategic decisions in science and business.
 
As the framework evolves, multiple functionalities have matured enough to become standalone packages.
 
This includes **[ReactiveDynamics.jl](https://github.com/Merck/ReactiveDynamics.jl)**, a package which implements a category of reaction (transportation) network-type dynamical systems. The central concept of the package is of a stateful, parametric transition; simultaneous action of the transitions then evolves the dynamical system. Moreover, a network's dynamics can be specified using a compact modeling metalanguage.
 
Another package is **[AlgebraicAgents.jl](https://github.com/Merck/AlgebraicAgents.jl)**, a lightweight package to enable hierarchical, heterogeneous dynamical systems co-integration. It implements a highly scalable, fully customizable interface featuring sums and compositions of dynamical systems. In present context, we note it can be used to co-integrate a reaction network problem with, e.g., a stochastic ordinary differential problem!

## Features

At the input is a general expression with (nested) expression comprehension atoms of the form `{<expression body>, <substitution ranges>, <local generator opts>}`. The substitution ranges yield an iterator over substitution choices; by default, this is a product over the ranges and the ranges are evaluated in a sequential order from left to right. Use `zip=true` within `<local generator opts>` to zip the iterators instead (Julia's standard zipping behavior).

For each substitution choice, expressions of the from `$sym` within `<expression body>` are substituted with the respective choices (otherwise left unchanged). The resulting vector of expressions is either wrapped into 1) a block expression or 2) a call expression. In the latter case, the function's name is specified in `dlm=<call name>`; additionally, `dlm=:(=)` is supported as well.

Note that in the above process, the substitution happens at the expression level. It is likewise possible to input a string, perform string substitutions according to rules described above, and parse the resulting string into an expression. Because of the internal parsing, an expression body containing a comma has to be escaped by another pair of angle brackets (`<` and `>`).

In addition, both function and macro forms accept top-level generation opts: you may 1) provide singular substitution ranges with global effect (interpolates corresponding `$sym`s within the expression at the input) and 2) evaluate the macros before returning the expression (the usecase is bound to the function form).

## Showcase

### Function form: retrieve generated expression


```julia-repl
julia> generate("{\$a+\$b, a=1:2, b=1:2}") |> println
1+1
1+2
2+1
2+2
```


```julia-repl
julia> generate("{\$a+\$b, a=1:2, b=1:2, zip=true}") |> println
1+1
2+2
```


```julia-repl
julia> generate("{<\$a+{\$b, b=1:\$a, dlm=+}>, a=1:2}") |> println
1+1
2+1+2
```


```julia-repl
julia> generate("{<\$a+{<\$b+{\$c, c=1:(\$a+\$b), dlm=+}>, b=1:\$a, dlm=+}>, a=1:2}") |> println
1+1+1+2
2+1+1+2+3+2+1+2+3+4
```


```julia-repl
julia> generate("""{\$a, a=["str_\$c" for c in 1:2], dlm=" "}""") |> println
str_1 str_2
```

### Macro form: evaluate generated expression


```julia-repl
julia> @generate {$a+$b, a=1:3, b=1:2, zip=true, dlm=+}
6
```


```julia-repl
julia> @generate {$a+$b, a=1:3, b=1:$a, dlm=+}
24
```


```julia-repl
julia> N=2; @generate "{<\$a+\$b+\$r>, a=1:3, b=1:\$a, r=N, dlm=+}"
36
```


```julia-repl
julia> a=b=c=1; @generate("{<\$[a,b,c]>, dlm=+}")
3
```


```julia-repl
julia> write("file_expr.jl", """{println(\$your_name, ", that is ", \$name), name=["bot_\$i" for i in 1:2]}""")
72

julia> @fileval file_expr.jl your_name="myself"
myself, that is bot_1
myself, that is bot_2
```


```julia-repl
julia> write("file_string.jl", """{<println("\$your_name, that is \$name")>, name=["bot_\$i" for i in 1:2]}""")
70

julia> @fileval file_string.jl mode=string your_name="myself"
myself, that is bot_1
myself, that is bot_2
```


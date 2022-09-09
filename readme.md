# GeneratedExpressions.jl: <br> Expression Comprehensions in Julia

<p align="center">
  <a href="#about">About</a> |
  <a href="#context-value-dynamics">Context</a> |
  <a href="#features">Features</a> |
  <a href="#showcase">Showcase</a> |
  <a href="#documentation">Documentation</a>
</p>

## About

The package implements a metalanguage to support code-less expression comprehensions in Julia. 

In particular, we provide a convenient proxy (inspired by mustache.js's notation) which takes an expression (string, alternatively), interpolates the $s in the expressions from ranges provided at the input, and then amalgamates the generated expressions into a block, a tuple, etc. 

It is possible to retrieve the generated expression (function `generate`) or to evaluate the expression in the caller's scope on the fly (macro `@generate`, `@fileval`).

## Context: ValueDynamics

This package was created as an integral part of the [ValueDynamics](https://github.com/Merck/ReactionDynamics.jl) project, which is a vertically-integrated computational framework for learning, designing, integrating, simulating, and optimizing R&D process models, to better inform strategic decisions in science and business. However, this package can be used on its own, independently of the larger framework.

## Features

At the input is a general expression with (nested) expression comprehension atoms of the form `{<expression body>, <substitution ranges>, <local generator opts>}`. The substitution ranges yield an iterator over substitution choices; by default, this is a product over the ranges and the ranges are evaluated in a sequential order from left to right. Use `zip=true` within `<local generator opts>` to zip the iterators instead (Julia's standard zipping behavior).

For each substitution choice, expressions of the from `$sym` within `<expression body>` are substituted with the respective choices (otherwise left unchanged). The resulting vector of expressions is either wrapped into 1) a block expression or 2) a call expression. In the latter case, the function's name is specified in `dlm=<call name>`; additionally, `dlm=:(=)` is supported as well.

Note that in the above process, the substitution happens at the expression level. It is likewise possible to input a string, perform string substitutions according to rules described above, and parse the resulting string into an expression. Because of the internal parsing, an expression body containing a comma has to be escaped by another pair of angle brackets (`<` and `>`).

In addition, both function and macro forms accept top-level generation opts: you may 1) provide singular substitution ranges with global effect (interpolates corresponding `$sym`s within the expression at the input) and 2) evaluate the macros before returning the expression (the usecase is bound to the function form).

## Showcase

### Function form: retrieve generated expression

```julia
julia> generate("{\$a+\$b, a=1:2, b=1:2}") |> println
1+1
1+2
2+1
2+2

julia> generate("{\$a+\$b, a=1:2, b=1:2, zip=true}") |> println
1+1
2+2

julia> generate("{<\$a+{\$b, b=1:\$a, dlm=+}>, a=1:2}") |> println
1+1
2+1+2

julia> generate("{<\$a+{<\$b+{\$c, c=1:(\$a+\$b), dlm=+}>, b=1:\$a, dlm=+}>, a=1:2}") |> println
1+1+1+2
2+1+1+2+3+2+1+2+3+4

julia> generate("""{\$a, a=["str_\$c" for c in 1:2], dlm=" "}""") |> println
"str_1 str_2"
```

### Macro form: evaluate generated expression

```julia
julia> @generate {$a+$b, a=1:3, b=1:2, zip=true, dlm=+}
75

julia> @generate {$a+$b, a=1:3, b=1:$a, dlm=+}
24

julia> N=2; @generate "{<\$a+\$b+\$r>, a=1:3, b=1:\$a, r=N, dlm=+}" 
36

julia> a=b=c=1; @generate("{<\$[a,b,c]>, dlm=+}")
3

julia> write("file_expr.jl", """{println(\$your_name, ", that is ", \$name), name=["bot_\$i" for i in 1:2]}""")
julia> @fileval file_expr.jl your_name="myself"
"""
myself, that is bot_1
myself, that is bot_2
"""

julia> write("file_string.jl", """{<println("\$your_name, that is \$name")>, name=["bot_\$i" for i in 1:2]}""")
julia> @fileval file_string.jl mode=string your_name="myself"
"""
myself, that is bot_1
myself, that is bot_2
"""
```

## Documentation

### `GeneratedExpressions.@generate` — _Macro._
```
@generate {<expression body>, <substitution ranges>, <local generator opts>} <generator opts>
@generate "{<<expression body>>, <substitution ranges>, <local generator opts>}" <generator opts>
```

Expand and evaluate parametrized expression comprehensions.

!!! When using the string form, an expression body containing a comma has to be escaped by another pair of angle brackets (`<` and `>`).

#### Examples
```julia
@generate {$a+$b, a=1:3, b=3:5, dlm=+, zip=true} eval_macros=true
@generate "{\$a+\$b, a=1:3, b=3:5, dlm=+, zip=true}"
a=b=c=1; @generate {$[a,b,c], dlm=+}
a=b=c=1; @generate("{<\$[a,b,c]>, dlm=+}")
```

### `GeneratedExpressions.generate` — _Function._
```    
generate(body, pre_substitution; eval_module, tl_opts)
```
Expand and evaluate parametrized expression comprehensions.

!!! Note that in expressions, `$sym` atoms have to be escaped as `:($sym)`.

#### Examples
```julia
generate("{\$a+\$b, a=1:3, b=3:5, dlm=+, zip=true}")
generate(:({:($a)+:($b)+:($c), a=1:3, b=3:5, dlm=+, zip=true}), Dict(:c=>2))
```

### `GeneratedExpressions.@fileval` — _Macro._
```
@fileval <path> <global opts> <substitutions (singleton range)>
```

Expand and evaluate parametrized expression comprehensions in a file, and evaluate the resulting expression.

#### Examples
```julia
@fileval "file.jl" x=1 # treat contents of "file.jl" as expression (parse first, then expand)
@fileval file_string.jl mode=string x=1 # first expand as string, then eval
```
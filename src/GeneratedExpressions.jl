module GeneratedExpressions

using MacroTools: prewalk, postwalk, isexpr
using Base.Iterators: zip, product

export @generate, @fileval
export generate

# substitution ranges, generator opts
const substitution_opts = Dict(:zip => false)
# topl-level opts
const tl_opts_default = Dict(:eval_macros => false, :mode => :expr, :toplevel_substitute => true, :lazy => false)

"Expression generator's opts."
struct GenOpts
    ranges; dlm; opts

    function GenOpts(exs, pre_substitutions; eval_module)
        dlm = kwargex_delete!(exs, :dlm, nothing)
        dlm = dlm isa String ? Symbol(dlm) : dlm isa QuoteNode ? dlm.value : dlm
        opts = Dict(opt => kwargex_delete!(exs, opt, defval) for (opt, defval) in substitution_opts)
        
        substitutions = opts[:zip] ? [ex.args[1] => get_val(generate(ex.args[2], pre_substitutions; eval_module); eval_module) for ex in exs] :
            [ex.args[1] => ex.args[2] for ex in exs]
    
        new(substitutions, dlm, opts)
    end
end

# expression generation, substitution utilities
include("expressions.jl")
# string generation, substitution utilities
include("strings.jl")

## fallbacks
eval_macros(ex; eval_module=@__MODULE__) = ex
generate(ex, pre_substitution; eval_module) = ex
substitute(ex, _) = ex

## generic methods
"""
    generate(body, pre_substitution; eval_module, tl_opts)

Expand and evaluate parametrized expression comprehensions.

!!! Note that in expressions, `\$sym`` atoms have to be escaped as `:(\$sym)`.

# Examples
```
generate("{\$a+\$b, a=1:3, b=3:5, dlm=+, zip=true}")
generate(:({:(\$a)+:(\$b)+:(\$c), a=1:3, b=3:5, dlm=+, zip=true}), Dict(:c=>2))
```
"""
function generate end

"Substitute and dlm the atomic `{expr}` blocks."
function generate_from_braces end
"Substitute the `\$` atomic escapes from a `view`."
function substitute end

"Return the (expression) value stored for the given key in a collection of keyword expression, or the given default value if no mapping for the key is present."
function kwargex_delete!(collection, key, default=:())
    ix = findfirst(ex -> ex.args[1] == key, collection)
    !isnothing(ix) ? (v = collection[ix].args[2]; deleteat!(collection, ix); v) : default
end

"Parse input `opts` and return generator options, pre-substitutions."
function get_opts(opts; eval_module=@__MODULE__)
    tl_opts = copy(tl_opts_default); pre_substitutions = Dict{Symbol, Any}()
    for opt in opts
        if isexpr(opt, :(=)) && (first(opt.args) ∈ keys(tl_opts))
            tl_opts[first(opt.args)] = last(opt.args)
        else push!(pre_substitutions, first(opt.args) => Base.eval(eval_module, last(opt.args))) end
    end

    tl_opts, pre_substitutions
end

"""
    @generate {<expression body>, <substitution ranges>, <local generator opts>} <generator opts>
    @generate "{<<expression body>>, <substitution ranges>, <local generator opts>}" <generator opts>

Expand and evaluate parametrized expression comprehensions.

!!! When using the string form, an expression body containing a comma has to be escaped by another pair of angle brackets (`<` and `>`).

# Examples
```
@generate {\$a+\$b, a=1:3, b=3:5, dlm=+, zip=true} eval_macros=true
@generate "{\$a+\$b, a=1:3, b=3:5, dlm=+, zip=true}"
a=b=c=1; @generate {\$[a,b,c], dlm=+}
a=b=c=1; @generate("{<\$[a,b,c]>, dlm=+}")
```
"""
macro generate(ex, opts...)
    tl_opts, pre_substitutions = get_opts(opts)
    tl_opts[:toplevel_substitute] && (ex = substitute(ex, pre_substitutions))
    ex = tl_opts[:lazy] ? ex : generate(ex, pre_substitutions; eval_module=__module__, tl_opts)

    esc(ex isa String ? Meta.parseall(ex) : ex)
end

"""
    @fileval <path> <global opts> <substitutions (singleton range)>

Expand and evaluate parametrized expression comprehensions in a file, and evaluate the resulting expression.
Use `mode=string` to process the input as a string (which is then parsed and evaluated).

# Examples
```
@fileval "file.jl" mode=expr x=1 # treat contents of "file.jl" as expression (parse first, then expand)
@fileval file_string.jl mode=string x=1 # first expand as string, then 
```
"""
macro fileval(pathex, opts...)
    tl_opts, pre_substitutions = get_opts(opts; eval_module=__module__)
    body = (tl_opts[:mode] == :string ? identity : Meta.parseall)(read(string(pathex), String))

    tl_opts[:toplevel_substitute] && (body = substitute(body, pre_substitutions))
    expr = tl_opts[:lazy] ? body : generate(body, pre_substitutions; eval_module=__module__, tl_opts)

    if tl_opts[:mode] == :string
        mktemp() do path, _
            write(path, expr)
            Base.include(__module__, path)
        end
    else Base.eval(__module__, expr) end
end

# auxiliary
"Join nested block expressions in `ex`."
function flatten!(ex)
    Meta.isexpr(ex, :block) || return ex

    args = []; for ex in ex.args
        Meta.isexpr(ex, :block) ? append!(args, ex.args) : push!(args, ex)
    end

    ex.args = args; ex
end

end
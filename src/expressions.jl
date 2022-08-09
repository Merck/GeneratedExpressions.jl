"Interpret `sym`."
get_val(sym; eval_module) = sym isa Symbol ? Base.eval(eval_module, sym) : collect(Base.eval(eval_module, sym))

"Match interpolatable \$ atoms."
is_atom(ex, view) = isexpr(ex, :$) && length(ex.args) == 1 && haskey(view, ex.args[1])

"Evaluate macro calls in `ex`."
function eval_macros(ex::Expr; eval_module=@__MODULE__)
    postwalk(ex -> isexpr(ex, :macrocall) ? macroexpand(eval_module, ex) : ex, ex)
end

# Expand and evaluate parametrized expression comprehensions.
function generate(ex::Expr, pre_substitutions=Dict{Symbol, Any}(); eval_module=@__MODULE__, tl_opts=tl_opts_default)
    ex = prewalk(ex -> generate_from_braces(ex, pre_substitutions; eval_module), ex)

    tl_opts[:eval_macros] ? eval_macros(ex; eval_module) : ex
end

"Escape `:bracescat`."
to_braces(ex) = isexpr(ex, :bracescat) ? first(ex.args) : ex

"Recursively construct a product over substitution ranges."
function view_product(view::Dict{Symbol, Any}, substitutions; eval_module)
    isempty(substitutions) && return [view]
    key, vals = substitutions[1]; substitutions_ = substitutions[2:end]
    vals = get_val(generate(vals, view; eval_module); eval_module)
    views = []; for val in vals
        append!(views, view_product(merge(view, Dict(key => val)), substitutions_; eval_module))
    end

    views
end

"Join the elements in `itr` into a nested :(=)-head type expression."
make_eq(itr) = length(itr) == 1 ? first(itr) : Expr(:(=), first(itr), make_eq(itr[2:end]))

# Substitute in and dlm the atomic `{expr}` blocks.
function generate_from_braces(ex, pre_substitutions=Dict{Symbol, Any}(); eval_module=@__MODULE__)
    isexpr(ex, :$) && return substitute(ex, pre_substitutions)
    (!isa(ex, Expr) || !isexpr(ex, :bracescat, :braces) || isempty(ex.args)) && return ex
    if isexpr(ex.args[1], :$) && !isa(ex.args[1].args[1], Symbol) 
        sym = gensym(); pushfirst!(ex.args, Expr(:$, sym))
        ex.args[2] = Expr(:(=), sym, first(ex.args[2].args))
    end

    ex_body = ex.args[1]
    genopts = GenOpts(ex.args[2:end], pre_substitutions; eval_module)

    ## take zip or product over the substitution ranges
    generated = []; mode = genopts.opts[:zip] ? zip : product
    if mode == zip
        view = Dict{Symbol, Any}()
        for view_ in zip((val for (_, val) in genopts.ranges)...)
            merge!(view, pre_substitutions); for (ix, k) in enumerate(k for (k, _) in genopts.ranges)
                view[k] = view_[ix]
            end
            push!(generated, substitute(ex_body, view))
        end
    elseif mode == product
        for view in view_product(pre_substitutions, genopts.ranges; eval_module)
            push!(generated, substitute(ex_body, view))
        end
    end

    isnothing(genopts.dlm) ? Expr(:block, generated...) :
        genopts.dlm == :(=) ? make_eq(generated) :
            Expr(:call, genopts.dlm, generated...)
end

# Interpolate the `\$` atomic escapes from a `view`.
function substitute(ex::Expr, view=Dict{Symbol, Any}())
    prewalk(ex -> is_atom(ex, view) ? view[ex.args[1]] : ex, ex)
end
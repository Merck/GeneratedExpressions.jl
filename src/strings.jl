## regex patterns to match aa (optionally multiline) commen
const regex_comment = r"(\#=(.|\n)*?(=\#|\Z)|(\#[^\n\r]*?(?:\*\)|[\n\r])))"

"Delete (Julia) comments in a string."
delete_comments(str::AbstractString) = replace(str, regex_comment => "\n")

# Expand and evaluate parametrized expression comprehensions.
function generate(str::AbstractString, pre_substitutions=Dict{Symbol, Any}(); eval_module=@__MODULE__, tl_opts=tl_opts_default)
    str = delete_comments(str)
    # iterate over comprehension atoms and expand them
    atom = get_atom(str)
    while !isnothing(atom)
        i1, i2, match = atom
        replacement = generate_from_braces(match..., pre_substitutions; eval_module, tl_opts)
        str = str[1:i1-1] * replacement * str[i2+1:end]
        atom = get_atom(str)
    end

    tl_opts[:eval_macros] ? eval_macros(str; eval_module) : str
end

"Retrieve the first expression comprehension atom."
function get_atom(str::AbstractString)
    # find first balanced pair of braces
    ixs = first_balanced(str, '{', '}')
    isnothing(ixs) && return nothing

    i1, i2 = ixs; atom = str[i1+1:i2-1]
    
    match = if isempty(atom); "", ""
    elseif atom[1] == '<'
        i = first_balanced(atom, '<', '>')[2]
        atom[2:i-1], get_optail(atom[i:end])
    else [split(atom, ',', limit=2); ""][1:2] end

    (i1, i2, match)
end

# extract generator opts
function get_optail(str)
    i = findfirst(==(','), str)
    
    isnothing(i) ? "" : str[nextind(str, i):end]
end

"Get position of the first balanced pair of `l` (left parenthesis) and `r` (right parenthesis)."
function first_balanced(str::AbstractString, l, r)
    i1 = findfirst(==(l), str); i2 = nothing
    isnothing(i1) && return nothing

    count_l = 1; count_r = 0
    for j in nextind(str, i1):lastindex(str)
        if str[j] == l; count_l += 1
        elseif str[j] == r; count_r += 1 end
        
        if count_r > count_l; @error("unbalanced braces")
        elseif count_l == count_r; i2 = j; break end
    end

    isnothing(i2) ? nothing : (i1, i2)
end

# Substitute and dlm the atomic `{expr}` blocks.
function generate_from_braces(body::AbstractString, opts_str::AbstractString, pre_substitutions=Dict{Symbol, Any}(); eval_module=@__MODULE__, tl_opts=tl_opts_default)
    opts = isempty(opts_str) ? nothing : Meta.parse("($opts_str,)")
    opts = isnothing(opts) ? Expr[] : isexpr(opts, :tuple) ? opts.args : [opts]

    body = (length(body) < 2 || body[1:2]) != "{{" ? body : body[3:end-2]
    parsed_body = try Meta.parse(body) catch nothing end
    if !isnothing(parsed_body) && isexpr(parsed_body, :$) && !isa(first(parsed_body.args), Symbol) 
        sym = gensym(); body = "\$$sym"
        push!(opts, Expr(:(=), sym, last(parsed_body.args)))
    end

    genopts = GenOpts(opts, pre_substitutions; eval_module)

    ## take zip or product over the substitution ranges
    generated = []; mode = genopts.opts[:zip] ? zip : product
    if mode == zip
        view = Dict{Symbol, Any}()
        for view_ in zip((val for (_, val) in genopts.ranges)...)
            merge!(view, pre_substitutions); for (ix, k) in enumerate(k for (k, _) in genopts.ranges)
                view[k] = view_[ix]
            end
            push!(generated, generate(substitute(body, view), view; eval_module, tl_opts))
        end
    elseif mode == product
        for view in view_product(pre_substitutions, genopts.ranges; eval_module)
            push!(generated, generate(substitute(body, view), view; eval_module, tl_opts))
        end
    end

    join(generated, string(isnothing(genopts.dlm) ? "\n" : genopts.dlm))
end

# Interpolate the `\$` atomic escapes from a `view`.
function substitute(str::AbstractString, view=Dict{Symbol, Any}())
    replace(str, ("\$"*string(sym) => string(val) for (sym, val) in view)...)
end
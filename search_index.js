var documenterSearchIndex = {"docs":
[{"location":"showcase.html","page":"-","title":"-","text":"using GeneratedExpressions; # hide\ngenerate(\"{\\$a+\\$b, a=1:2, b=1:2}\") |> println","category":"page"},{"location":"showcase.html","page":"-","title":"-","text":"using GeneratedExpressions; # hide\ngenerate(\"{\\$a+\\$b, a=1:2, b=1:2, zip=true}\") |> println","category":"page"},{"location":"showcase.html","page":"-","title":"-","text":"using GeneratedExpressions; # hide\ngenerate(\"{<\\$a+{\\$b, b=1:\\$a, dlm=+}>, a=1:2}\") |> println","category":"page"},{"location":"showcase.html","page":"-","title":"-","text":"using GeneratedExpressions; # hide\ngenerate(\"{<\\$a+{<\\$b+{\\$c, c=1:(\\$a+\\$b), dlm=+}>, b=1:\\$a, dlm=+}>, a=1:2}\") |> println","category":"page"},{"location":"showcase.html","page":"-","title":"-","text":"using GeneratedExpressions; # hide\ngenerate(\"\"\"{\\$a, a=[\"str_\\$c\" for c in 1:2], dlm=\" \"}\"\"\") |> println","category":"page"},{"location":"showcase.html","page":"-","title":"-","text":"using GeneratedExpressions; # hide\n@generate {$a+$b, a=1:3, b=1:2, zip=true, dlm=+}","category":"page"},{"location":"showcase.html","page":"-","title":"-","text":"using GeneratedExpressions; # hide\n@generate {$a+$b, a=1:3, b=1:$a, dlm=+}","category":"page"},{"location":"showcase.html","page":"-","title":"-","text":"using GeneratedExpressions; # hide\nN=2; @generate \"{<\\$a+\\$b+\\$r>, a=1:3, b=1:\\$a, r=N, dlm=+}\" ","category":"page"},{"location":"showcase.html","page":"-","title":"-","text":"using GeneratedExpressions; # hide\na=b=c=1; @generate(\"{<\\$[a,b,c]>, dlm=+}\")","category":"page"},{"location":"showcase.html","page":"-","title":"-","text":"using GeneratedExpressions; # hide\nwrite(\"file_expr.jl\", \"\"\"{println(\\$your_name, \", that is \", \\$name), name=[\"bot_\\$i\" for i in 1:2]}\"\"\")\n\n@fileval file_expr.jl your_name=\"myself\"","category":"page"},{"location":"showcase.html","page":"-","title":"-","text":"using GeneratedExpressions; # hide\nwrite(\"file_string.jl\", \"\"\"{<println(\"\\$your_name, that is \\$name\")>, name=[\"bot_\\$i\" for i in 1:2]}\"\"\")\n\n@fileval file_string.jl mode=string your_name=\"myself\"","category":"page"},{"location":"index.html#API-Documentation","page":"API Documentation","title":"API Documentation","text":"","category":"section"},{"location":"index.html","page":"API Documentation","title":"API Documentation","text":"Modules = [GeneratedExpressions]\nPrivate = false","category":"page"},{"location":"index.html#GeneratedExpressions.generate","page":"API Documentation","title":"GeneratedExpressions.generate","text":"generate(body, pre_substitution; eval_module, tl_opts)\n\nExpand and evaluate parametrized expression comprehensions.\n\n!!! Note that in expressions, $symatoms have to be escaped as:(sym)`.\n\nExamples\n\ngenerate(\"{$a+$b, a=1:3, b=3:5, dlm=+, zip=true}\")\ngenerate(:({:($a)+:($b)+:($c), a=1:3, b=3:5, dlm=+, zip=true}), Dict(:c=>2))\n\n\n\n\n\n","category":"function"},{"location":"index.html#GeneratedExpressions.@fileval-Tuple{Any, Vararg{Any}}","page":"API Documentation","title":"GeneratedExpressions.@fileval","text":"@fileval <path> <global opts> <substitutions (singleton range)>\n\nExpand and evaluate parametrized expression comprehensions in a file, and evaluate the resulting expression. Use mode=string to process the input as a string (which is then parsed and evaluated).\n\nExamples\n\n@fileval \"file.jl\" mode=expr x=1 # treat contents of \"file.jl\" as expression (parse first, then expand)\n@fileval file_string.jl mode=string x=1 # first expand as string, then \n\n\n\n\n\n","category":"macro"},{"location":"index.html#GeneratedExpressions.@generate-Tuple{Any, Vararg{Any}}","page":"API Documentation","title":"GeneratedExpressions.@generate","text":"@generate {<expression body>, <substitution ranges>, <local generator opts>} <generator opts>\n@generate \"{<<expression body>>, <substitution ranges>, <local generator opts>}\" <generator opts>\n\nExpand and evaluate parametrized expression comprehensions.\n\n!!! When using the string form, an expression body containing a comma has to be escaped by another pair of angle brackets (< and >).\n\nExamples\n\n@generate {$a+$b, a=1:3, b=3:5, dlm=+, zip=true} eval_macros=true\n@generate \"{$a+$b, a=1:3, b=3:5, dlm=+, zip=true}\"\na=b=c=1; @generate {$[a,b,c], dlm=+}\na=b=c=1; @generate(\"{<$[a,b,c]>, dlm=+}\")\n\n\n\n\n\n","category":"macro"}]
}

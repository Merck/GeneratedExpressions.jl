using GeneratedExpressions: @generate, generate, @fileval

macro add(ex) ex+1 end

@generate {$a+@add($b), a=1:3, b=3:5, dlm=+, zip=true} eval_macros=true
N=2; @generate {$a+$b+{$c, c=1:6, dlm=+}, a=1:3, b=1:3, zip=true, dlm=+}
N=2; @generate {$a+$b+{$c, c=1:6, dlm=+}, a=1:3, b=1:3, dlm=+}
a=b=c=1; @generate {$[a,b,c], dlm=+}

generate("{\$a+\$b, a=1:3, b=3:5, dlm=+, zip=true}")
N=2; @generate("{<\$a+\$b+{\$c, c=1:6, dlm=+}+\$r>, a=1:3, b=rand(), r=N}")
a=b=c=1; @generate("{<\$[a,b,c]>, dlm=+}")

@generate "@add(2)" eval_macros=true
@generate "{\$a+@add(\$b), a=1:3, b=3:5, dlm=+, zip=true}" eval_macros=true

@fileval file_expr.jl your_name="myself"
@fileval file_string.jl mode=string your_name="myself"
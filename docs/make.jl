using Documenter, DocumenterMarkdown
using GeneratedExpressions

makedocs(sitename="GeneratedExpressions.jl", build="build_html", format = Documenter.HTML(prettyurls = false, edit_link=nothing))
makedocs(sitename="GeneratedExpressions.jl", build="build_md", format = Markdown())
using ProtoMarketData
using Documenter

DocMeta.setdocmeta!(ProtoMarketData, :DocTestSetup, :(using ProtoMarketData); recursive=true)

makedocs(;
    modules=[ProtoMarketData],
    authors="Andrey Oskin",
    repo="https://github.com/Arkoniak/ProtoMarketData.jl/blob/{commit}{path}#{line}",
    sitename="ProtoMarketData.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://Arkoniak.github.io/ProtoMarketData.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/Arkoniak/ProtoMarketData.jl",
)

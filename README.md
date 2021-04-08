# ProtoMarketData


This package is a proof of concept of TimeTable interface, which is a small extension of Tables.jl. This project should be used for demonstration purposes only, since it contains heavy pirating of `TimeSeries.jl`, `Temporal.jl` and `Timestamps.jl`.

## Workspace preparation

Since methods of different packages are pirated, internal versions should be used. Messages like "recompilation can be broken" should be ignored, since it is an expected behaviour. Ideally these methods should land in respective packages and no messages of this kind appear.

Since package is not registered it should be installed with

```julia
julia> using Pkg; Pkg.dev("https://github.com/Arkoniak/ProtoMarketData.jl")
```

To prepare workspace do 

```julia
using ProtoMarketData
using Indicators
using MarketTechnicals

const TSPArray = ProtoMarketData.Timestamps.TimestampArray
const DataFrame = ProtoMarketData.DataFrames.DataFrame
const TimeArray = ProtoMarketData.TimeSeries.TimeArray
const TS = ProtoMarketData.Temporal.TS
```

## Data downloading

In this approach, all data sources emit special `WrapperTimeTable` which has `istimetable` trait. As `TimeTable` it contains information regarding time axis and all other interfaces are modified to respect `timeaxis` information

```julia
julia> raw = yahoo("SPY")
ProtoMarketData.WrapperTimeTable{CSV.File{true}}(:Date, CSV.File("<raw buffer>"):
Size: 7098 x 7
Tables.Schema:
 :Date                Date
 :Open                Float64
 :High                Float64
 :Low                 Float64
 :Close               Float64
 Symbol("Adj Close")  Float64
 :Volume              Int64)
```

This wrapper object can be transformed to any `TimeTable` types

```julia
julia> tsp1 = TSPArray(raw)
7098×6 Timestamps.TimestampArray{Date, Tuple{Float64, Float64, Float64, Float64, Float64, Int64
}}:
 1993-01-29 | (43.96875, 43.96875, 43.75, 43.9375, 25.884184, 1003200)
 1993-02-01 | (43.96875, 44.25, 43.96875, 44.25, 26.068277, 480500)
 1993-02-02 | (44.21875, 44.375, 44.125, 44.34375, 26.123499, 201300)
 1993-02-03 | (44.40625, 44.84375, 44.375, 44.8125, 26.399649, 529400)
 ⋮

julia> ta1 = TimeArray(raw)
7098×6 TimeSeries.TimeArray{Float64, 2, Date, Matrix{Float64}} 1993-01-29 to 2021-04-07
│            │ Open    │ High    │ Low     │ Close   │ Adj Close │ Volume     │
├────────────┼─────────┼─────────┼─────────┼─────────┼───────────┼────────────┤
│ 1993-01-29 │ 43.9688 │ 43.9688 │ 43.75   │ 43.9375 │ 25.8842   │ 1.0032e6   │
│ 1993-02-01 │ 43.9688 │ 44.25   │ 43.9688 │ 44.25   │ 26.0683   │ 480500.0   │
│ 1993-02-02 │ 44.2188 │ 44.375  │ 44.125  │ 44.3438 │ 26.1235   │ 201300.0   │
│ 1993-02-03 │ 44.4062 │ 44.8438 │ 44.375  │ 44.8125 │ 26.3996   │ 529400.0   │
 ⋮

julia> ts1 = TS(raw)
7098x6 Temporal.TS{Float64, Date}: 1993-01-29 to 2021-04-07

Index       Open      High      Low       Close     Adj Close  Volume
1993-01-29  43.9688   43.9688   43.75     43.9375   25.8842    1.0032e6
1993-02-01  43.9688   44.25     43.9688   44.25     26.0683    480500.0
1993-02-02  44.2188   44.375    44.125    44.3438   26.1235    201300.0
1993-02-03  44.4062   44.8438   44.375    44.8125   26.3996    529400.0
 ⋮
```

Since this object is also `Tables.jl` object any other sinks can used it too (of course, time axis information is lost in this case)

```julia
julia> df = DataFrame(raw)
7098×7 DataFrame
  Row │ Date        Open      High      Low       Close     Adj Close  Volume
      │ Date        Float64   Float64   Float64   Float64   Float64    Int64
──────┼──────────────────────────────────────────────────────────────────────────
    1 │ 1993-01-29   43.9688   43.9688   43.75     43.9375    25.8842    1003200
    2 │ 1993-02-01   43.9688   44.25     43.9688   44.25      26.0683     480500
    3 │ 1993-02-02   44.2188   44.375    44.125    44.3438    26.1235     201300
    4 │ 1993-02-03   44.4062   44.8438   44.375    44.8125    26.3996     529400
 ⋮
```

## Data conversion

Since all `TimeTable` types support `timeaxis` data, you can freely transform time tables from one type to another

```julia
# From timestamps to TS
julia> tsp1 |> TS
7098x6 Temporal.TS{Float64, Date}: 1993-01-29 to 2021-04-07

Index       Open      High      Low       Close     Adj Close  Volume
1993-01-29  43.9688   43.9688   43.75     43.9375   25.8842    1.0032e6
1993-02-01  43.9688   44.25     43.9688   44.25     26.0683    480500.0
1993-02-02  44.2188   44.375    44.125    44.3438   26.1235    201300.0
1993-02-03  44.4062   44.8438   44.375    44.8125   26.3996    529400.0
 ⋮

# Further from TS to TimeArray
julia> tsp1 |> TS |> TimeArray
7098×6 TimeSeries.TimeArray{Float64, 2, Date, Matrix{Float64}} 1993-01-29 to 2021-04-07
│            │ Open    │ High    │ Low     │ Close   │ Adj Close │ Volume     │
├────────────┼─────────┼─────────┼─────────┼─────────┼───────────┼────────────┤
│ 1993-01-29 │ 43.9688 │ 43.9688 │ 43.75   │ 43.9375 │ 25.8842   │ 1.0032e6   │
│ 1993-02-01 │ 43.9688 │ 44.25   │ 43.9688 │ 44.25   │ 26.0683   │ 480500.0   │
│ 1993-02-02 │ 44.2188 │ 44.375  │ 44.125  │ 44.3438 │ 26.1235   │ 201300.0   │
│ 1993-02-03 │ 44.4062 │ 44.8438 │ 44.375  │ 44.8125 │ 26.3996   │ 529400.0   │
 ⋮

# And back to Timestamps
julia> tsp1 |> TS |> TimeArray |> TSPArray
7098×6 Timestamps.TimestampArray{Date, NTuple{6, Float64}}:
 1993-01-29 | (43.96875, 43.96875, 43.75, 43.9375, 25.884184, 1.0032e6)
 1993-02-01 | (43.96875, 44.25, 43.96875, 44.25, 26.068277, 480500.0)
 1993-02-02 | (44.21875, 44.375, 44.125, 44.34375, 26.123499, 201300.0)
 1993-02-03 | (44.40625, 44.84375, 44.375, 44.8125, 26.399649, 529400.0)
 ⋮
```

Since all transformations support `timestamp` keyword as a fallback, even non timetable types can be used in transformation chains, yet slightly less convenient

```julia
# Convert DataFrame to Timestamps and than to TS
julia> TSPArray(df; timestamp = :Date) |> TS
7098x6 Temporal.TS{Float64, Date}: 1993-01-29 to 2021-04-07

Index       Open      High      Low       Close     Adj Close  Volume
1993-01-29  43.9688   43.9688   43.75     43.9375   25.8842    1.0032e6
1993-02-01  43.9688   44.25     43.9688   44.25     26.0683    480500.0
1993-02-02  44.2188   44.375    44.125    44.3438   26.1235    201300.0
1993-02-03  44.4062   44.8438   44.375    44.8125   26.3996    529400.0
 ⋮

```

## Benefits

One immediate benefit of this transparent and seamless conversions is possibility to use any package to make any kind of calculations, if current type has no support for any particular operation. This way calculations can be gathered in one huge package or spread in dozen of small focused packages, user can use them all. Of course, one should be careful and not use conversions in tight loops. Still it covers lot of practical cases.

### Example 1

There is no `PSAR` indicator at the moment for `TimeArray` type in `MarketTechnicals.jl`, but there is one in `Indicators.jl` for `Temporal`

```julia
julia> ta1 |> TS |> psar |> TimeArray
7098×1 TimeSeries.TimeArray{Float64, 1, Date, Vector{Float64}} 1993-01-29 to 2021-04-07
│            │ PSAR     │
├────────────┼──────────┤
│ 1993-01-29 │ 42.0817  │
│ 1993-02-01 │ 42.1195  │
│ 1993-02-02 │ 42.2047  │
│ 1993-02-03 │ 42.3349  │
 ⋮
```

### Example 2
We can compare different implementations of simple moving average between different libraries

```julia
julia> MarketTechnicals.sma(ta1[[:Close]], 3) |> TS
7096x1 Temporal.TS{Float64, Date}: 1993-02-02 to 2021-04-07

Index       Close_sma_3
1993-02-02  44.1771
1993-02-03  44.4688
1993-02-04  44.7188
 ⋮

julia> Indicators.sma(TS(ta1[[:Close]]), n = 3)
7098x1 Temporal.TS{Float64, Date}: 1993-01-29 to 2021-04-07

Index       SMA
1993-01-29  NaN
1993-02-01  NaN
1993-02-02  44.1771
1993-02-03  44.4688
1993-02-04  44.7188
 ⋮
```

### Example 3

We can apply `MarketTechnicals.rsi` and convert result in `TimestampArray` for further usage in backtesting

```julia
julia> tsp1 |> TimeArray |> x -> x[[:Close]] |> MarketTechnicals.rsi |> TSPArray
7084×1 Timestamps.TimestampArray{Date, Tuple{Float64}}:
 1993-02-19 | (44.444444444444436,)
 1993-02-22 | (49.4818652849741,)
 1993-02-23 | (48.46769471013078,)
 1993-02-24 | (63.854279665925915,)
 1993-02-25 | (65.81704734556533,)
 ⋮
```

We can apply `Indicators.macd` for the same reason

```
julia> tsp1 |> TS |> Indicators.macd |> TSPArray
7098×3 Timestamps.TimestampArray{Date, Tuple{Float64, Float64, Float64}}:
 1993-01-29 | (NaN, NaN, NaN)
 1993-02-01 | (NaN, NaN, NaN)
 ⋮
 2021-03-05 | (0.24446773578944203, 1.9126881594256007, -1.6682204236361586)
 2021-03-08 | (-0.001533747188830148, 1.5243867936480027, -1.5259205408368328)
 2021-03-09 | (0.23908709375064063, 1.162151050415692, -0.9230639566650514)
 ⋮
```

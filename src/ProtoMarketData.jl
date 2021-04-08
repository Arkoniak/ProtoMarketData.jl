module ProtoMarketData

import HTTP
import Timestamps
import Temporal
import TimeSeries
import DataFrames
import Tables
import Dates
import Dates: DateTime, datetime2unix
import CSV

export yahoo

struct YahooOpt
    period1::DateTime
    period2::DateTime
    interval::String
    events::String
end
function YahooOpt(; period1::DateTime = DateTime(1971, 2, 8),
                    period2::DateTime = Dates.now(),
                    interval::String  = "1d",
                    events::Symbol    = "history")
    YahooOpt(period1, period2, interval, events)
end

function asquery(yo::YahooOpt)
    return ("period1" => round(Int, datetime2unix(yo.period1)),
            "period2" => round(Int, datetime2unix(yo.period2)),
            "interval" => yo.interval,
            "events" => yo.events)
end

function yahoo(sym; period1 = DateTime(1971, 2, 8), period2 = Dates.now(), interval = "1d", events = "history")
    yo = YahooOpt(period1, period2, interval, events)
    yahoo(sym, yo)
end

function yahoo(sym, yo::YahooOpt)
    host = rand(("query1", "query2"))
    url  = "https://$host.finance.yahoo.com/v7/finance/download/$sym"
    res  = HTTP.get(url, query = asquery(yo))
    res.status == 200 || throw("Error requesting yahoo $res")
    csv = CSV.File(res.body, missingstrings = ["null"])
    return WrapperTimeTable(:Date, csv)
end

########################################
# Glueing part
########################################

struct WrapperTimeTable{T}
    tscol::Symbol
    data::T
end

# Tables interface
Tables.istable(::Type{<:WrapperTimeTable}) = true
Tables.rowaccess(::Type{<:WrapperTimeTable}) = true
Tables.columnaccess(::Type{<:WrapperTimeTable}) = true
Tables.rows(m::WrapperTimeTable) = Tables.rows(m.data)
Tables.columns(m::WrapperTimeTable) = Tables.columns(m.data)
Tables.schema(m::WrapperTimeTable) = Tables.schema(m.data)
Tables.columnnames(m::WrapperTimeTable) = Tables.columnnames(m.data)

# Time tables interface
Timestamps.istimetable(::Type{<:WrapperTimeTable}) = true
Timestamps.timeaxis(x::WrapperTimeTable) = x.tscol

########################################
# Pirating TimeArray
########################################

Timestamps.istimetable(::Type{<:TimeSeries.TimeArray}) = true
Timestamps.timeaxis(x::TimeSeries.TimeArray) = :timestamp

function TimeSeries.TimeArray(x; timestamp::Symbol = Timestamps.timeaxis(x), timeparser::Base.Callable = identity,
                              unchecked = false)
    Tables.istable(x) || throw(ArgumentError("TimeArray requires a table as input"))

    sch = Tables.schema(x)
    names = sch.names
    (timestamp ∉ names) && throw(ArgumentError("time index `$timestamp` not found"))
    names′ = filter(!isequal(timestamp), collect(sch.names))

    cols = Tables.columns(x)
    val = mapreduce(n -> collect(Tables.getcolumn(cols, n)), hcat, names′)
    TimeSeries.TimeArray(map(timeparser, Tables.getcolumn(cols, timestamp)), val, names′, x;
              unchecked = unchecked)
end

########################################
# Pirating Temporal
########################################
Timestamps.istimetable(::Type{<:Temporal.TS}) = true
Timestamps.timeaxis(::Temporal.TS) = :timestamp
Tables.istable(::Type{<:Temporal.TS}) = true
Tables.columnnames(x::Temporal.TS) = [:timestamp, x.fields...]
Tables.schema(x::Temporal.TS) = Tables.Schema(tuple(Tables.columnnames(x)...), nothing)
Tables.columns(x::Temporal.TS) = x
function Tables.getcolumn(x::Temporal.TS, nm::Symbol)
    nm == :timestamp && return x.index
    vec(x.values[:, x.fields .== nm])
end

struct TSRowIterator{T1, T2 <: Tuple}
    m::T1
    names::T2
end

Tables.rows(x::Temporal.TS) = TSRowIterator(x, tuple(Tables.columnnames(x)...))
function Base.iterate(x::TSRowIterator, i = 1)
    m = x.m
    i > size(m, 1) && return nothing
    return (NamedTuple{x.names}((m.index[i], m.values[i, :]...)), i+1)
end
Base.length(x::TSRowIterator) = size(x.m, 1)

function Temporal.TS(x; timestamp = Timestamps.timeaxis(x), timeparser::Base.Callable = identity)
    Tables.istable(x) || throw(ArgumentError("TimeArray requires a table as input"))

    sch = Tables.schema(x)
    names = sch.names
    (timestamp ∉ names) && throw(ArgumentError("time index `$timestamp` not found"))
    names′ = filter(!isequal(timestamp), collect(sch.names))

    cols = Tables.columns(x)
    val = mapreduce(n -> collect(Tables.getcolumn(cols, n)), hcat, names′)
    Temporal.TS(val, map(timeparser, Tables.getcolumn(cols, timestamp)), names′)
end

end

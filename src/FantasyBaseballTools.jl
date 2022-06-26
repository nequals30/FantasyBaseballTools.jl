module FantasyBaseballTools 

using Dates, HTTP, CSV, DataFrames

export get_dougStats_data

"""
    get_dougStats_data(dt::Date, batterOrPitcher::AbstractString="batter") -> DataFrame

Download player data from dougstats.com and returns a DataFrame.

# Arguments
* `dt`: The as-of-date of the data
* `batterOrPitcher`: "batter" or "pitcher" data

# Examples
```jldoctest
julia> get_dougStats_data(Date(2022,06,19),"pitcher")
```
"""
function get_dougStats_data(dt::Date, batterOrPitcher::AbstractString="batter")
    url = "http://dougstats.com/" * Dates.format(dt,"yyyy") * "Data/" * Dates.format(dt,"mmdd") * lowercase(batterOrPitcher[1])
    r = HTTP.request("GET",url)
    body_contents = r.body[7:(end-8)]
    body_csv = CSV.File(IOBuffer(body_contents), delim=' ', ignorerepeated=true)
    DataFrame(body_csv)
end

end # module


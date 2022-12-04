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



function yahoo_connect(updateClientInfo::Bool=false)
    if !isfile("./yahoo_client_info.toml") || updateClientInfo
        c_id,c_secret = yahoo_registerApplication()
    else
        file = open("./yahoo_client_info.toml")
        for line in eachline(file)
            thisLine = split(line," = ")
            if lowercase(strip(thisLine[1])) == "client id"
                c_id = replace(strip(thisLine[2]),"\""=>"")
            elseif lowercase(strip(thisLine[1])) == "client secret"
                c_secret = replace(strip(thisLine[2]),"\""=>"")
            end
        end
        close(file)
    end
    # if you don't have a token, or the token is stale, then:
    yahoo_oauth2_authorizationRequest(c_id)

end

function yahoo_registerApplication()
    println("""Go here to to register an 'application':
    https://developer.yahoo.com/apps/create/

    It will give you a 'Client ID' and a 'Client Secret'. Enter them here:
    Client ID:""")
    file = open("./yahoo_client_info.toml","w")
    c_id = readline()
    println("Client Secret:")
    c_secret = readline()
    write(file,"Client ID = \""*c_id*"\"\n")
    write(file,"Client Secret = \""*c_secret*"\"\n")
    close(file)
    return c_id, c_secret
end

function yahoo_oauth2_authorizationRequest(client_id)
    authorize_url = "https://api.login.yahoo.com/oauth2/request_auth?redirect_uri=oob&response_type=code&client_id=" * client_id
    println("Please go to this link in your browser:\n" * authorize_url)
    println("Enter Verifier:")
    verifier = readline()
end
    
end # module


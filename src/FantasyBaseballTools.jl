module FantasyBaseballTools 

using Dates, HTTP, CSV, DataFrames, Base64, JSON

export get_dougStats_data, yahoo_connect

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
    yahoo_oauth2_authorizationRequest(c_id,c_secret)

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

function yahoo_oauth2_authorizationRequest(client_id,client_secret)
    # Direct the user to the authentication page and ask for the verifier
    authorize_url = "https://api.login.yahoo.com/oauth2/request_auth?redirect_uri=oob&response_type=code&client_id=" * client_id
    println("Please go to this link in your browser:\n" * authorize_url)
    println("Enter Verifier:")
    verifier = readline()

    # Make an HTTP POST request to get the access token
    url_getToken = "https://api.login.yahoo.com/oauth2/get_token"
    headers = Dict("Content-Type" => "application/x-www-form-urlencoded",
                   "Authorization" => "Basic "*base64encode(client_id*":"*client_secret))
    payload = Dict("grant_type" => "authorization_code",
                  "client_id" => client_id,
                  "client_secret" => client_secret,
                  "redirect_uri" => "oob",
                  "code" => verifier)
    response = HTTP.post(url_getToken,headers,payload)
    rawData = JSON.parse(String(response.body))

    # Write to file
    file = open("./yahoo_oauth_token.toml","w")
    write(file,"Refresh Token = \""*rawData["refresh_token"]*"\"\n")
    write(file,"Access Token = \""*rawData["access_token"]*"\"\n")
    close(file)
end

function yahoo_oauth2_refreshToken()
    # Read the saved refresh token
    token = ""
    c_id = ""
    c_secret = ""
    file = open("./yahoo_oauth_token.toml")
    for line in eachline(file)
        thisLine = split(line," = ")
        if lowercase(strip(thisLine[1])) == "refresh token"
            token = replace(strip(thisLine[2]),"\""=>"")
        end
    end
    close(file)

    # Read the client id and secret again
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

    # Make an HTTP POST request to get the access token
    url_refreshToken = "https://api.login.yahoo.com/oauth2/get_token"
    headers = Dict("Content-Type" => "application/x-www-form-urlencoded")
    payload = Dict("grant_type" => "refresh_token",
                  "client_id" => c_id,
                  "client_secret" => c_secret,
                  "refresh_token" => token)
    response = HTTP.post(url_refreshToken,headers,payload)
    rawData = JSON.parse(String(response.body))

    # Re-write the saved tokens
    file = open("./yahoo_oauth_token.toml","w")
    write(file,"Refresh Token = \""*rawData["refresh_token"]*"\"\n")
    write(file,"Access Token = \""*rawData["access_token"]*"\"\n")
    close(file)
end

function yahoo_get_data(league_id,game_id)
    # Read the saved token
    token = ""
    file = open("./yahoo_oauth_token.toml")
    for line in eachline(file)
        thisLine = split(line," = ")
        if lowercase(strip(thisLine[1])) == "access token"
            token = replace(strip(thisLine[2]),"\""=>"")
        end
    end
    close(file)

    # Make an HTTP get request for the data
    url = "https://fantasysports.yahooapis.com/fantasy/v2/league/"*string(game_id)*".l."*string(league_id)*"/players;start=25;count=25"
    headers = Dict("Authorization" => "Bearer "*token)
     println(headers)
    response = HTTP.get(url,headers)
    return response

end

end # module


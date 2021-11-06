include("list_courts.jl")
using HTTP
using Gumbo
using Cascadia
using Dates

# The max number of query results displayed is 400.
# We cannot scrape all the data avaiable.
# So we need to use optimized query.
# We are using an improved/degenerated version of bianry search


function generate_query(court::String, start_year::String):: String
    # Better if we use future dates instead of current date
    current_date = Dates.format(Dates.today(), "d-m-Y")
    base_url = "https://indiankanoon.org/search/?formInput=doctypes:"
    query = base_url * court * " "
    query *= "fromdate:1-1-" * start_year * " "
    query *= "todate:"*current_date
    return query
end

function generate_query(court::String, start_date::Date, end_date::Date):: String
    base_url = "https://indiankanoon.org/search/?formInput=doctypes:"
    date1 = Dates.format(start_date, "d-m-Y")
    date2 = Dates.format(end_date, "d-m-Y")
    
    query = base_url * court * " "
    query *= "fromdate:" * date1 * " "
    query *= "todate:" * date2
    return query
end

function get_number_of_results(query::String):: Int
    r = HTTP.get(query)
    doc = parsehtml(String(r.body))

    # Go into results middle.
    middle_section = eachmatch(Selector(".results_middle"), doc.root)[1]
    query_info = nodeText(eachmatch(Selector("b"), middle_section)[1])
    no_of_results = parse(Int, split(query_info, " ")[end])
    return no_of_results
    query_info
end

function get_optimal_query(court::String, start_year:: String)
    if start_year == "-1"
        return ""
    end

    start_date = Date("1-1-" * start_year, "d-m-y")
    curr_date = Dates.today()
    query = generate_query(court, start_date, curr_date)
    return query
end

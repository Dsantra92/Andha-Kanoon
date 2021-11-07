using HTTP
using Gumbo
using Cascadia
using Dates
include("utils.jl")
include("years.jl")

"""
Generates a search query given starting date and ending dates.
"""
function generate_query(court_id::String, start_date::Date, end_date::Date):: String
    base_url = "https://indiankanoon.org/search/?formInput=doctypes:"
    date1 = Dates.format(start_date, "d-m-Y")
    date2 = Dates.format(end_date, "d-m-Y")
    
    query = base_url * court_id * " "
    query *= "fromdate:" * date1 * " "
    query *= "todate:" * date2
    return query
end


function generate_initial_query(court_id::String, year::String)
    start_date = Date("1-1-" * year, "d-m-y")
    end_date = Date("31-1-" * year, "d-m-y")
    return generate_query(court_id, start_date, end_date)
end


"""
Returns the actual number of results of the query.
"""
function get_number_of_results(query::String)
    doc = get_html(query)
    query_info = nodeText(eachmatch(Selector("b"), doc.root)[1])
    
    no_of_results = parse(Int, split(query_info, " ")[5])
    return no_of_results
end




function get_optimal_query(court_id::String, years:: Vector{String})
    if start_year == "-1"
        return ""
    end

    start_date = Date("1-1-" * start_year, "d-m-y")
    curr_date = Dates.today()
    query = generate_query(court, start_date, curr_date)
    return query
end

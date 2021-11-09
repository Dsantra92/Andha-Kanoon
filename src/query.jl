using HTTP
using Gumbo
using Cascadia
using Dates
include("utils.jl")
include("years.jl")

"""
Generates a search query given starting date and ending dates.
"""
function generate_query(court_id::String, start_date::Date, end_date::Date)::String
    base_url = "https://indiankanoon.org/search/?formInput=doctypes:"
    date1 = Dates.format(start_date, "d-m-Y")
    date2 = Dates.format(end_date, "d-m-Y")

    query = base_url * court_id * " "
    query *= "fromdate:" * date1 * " "
    query *= "todate:" * date2
    return query
end

"""
Generates the initial query for a given court and year.
"""
function generate_initial_query(court_id::String, query_year::String)::String
    start_date = Date("1-1-" * query_year, "d-m-y")
    end_date = Date("31-12-" * query_year, "d-m-y")
    return generate_query(court_id, start_date, end_date)
end

"""
Returns the actual number of results for the query.
"""
function get_number_of_results(html_query_page:: HTMLDocument)::Int
    query_info = nodeText(eachmatch(Selector("b"), html_query_page.root)[1])

    no_of_results = parse(Int, split(query_info, " ")[5])
    return no_of_results
end

# Not recommended to use this function. Just for safety
function get_number_of_results(query:: String)::Int
    return get_number_of_results(get_html(query))
end


function generate_date_with_gaps(date1::Date, date2::Date, gap::Day, queries::Int)::Vector{Tuple{Date, Date}}
    date_list = Vector{Tuple{Date, Date}}(undef, queries)

    date_list[1] = (date1, date1 + gap)

    for i in range(2, queries-1)
        new_date = date_list[i-1][2] + Day(1)
        date_list[i] = (new_date, new_date + gap)
    end
    date_list[end] = (date_list[end-1][2] + Day(1), date2)
    return date_list
end


"""
Generates the pseudo-optimal query for a given court.
To be called only when the query results > 400.
"""
function get_sub_optimal_query(court_id::String, date1::Date, date2::Date, n_results::Int)::Vector{String}
    total_days = date2 - date1
    # Considering the number of cases to be unifromly distributed over the total days.
    # We expect the number of cases to be less than 400 for each query.
    n_queries = Int(ceil(n_results / 400))
    n_days = total_days ÷ n_queries - Day(1)
    new_dates = generate_date_with_gaps(date1, date2, n_days, n_queries)

    query_list = Vector{String}(undef, length(new_dates))
    for (i, dates) in enumerate(new_dates)
        query_list[i] = generate_query(court_id, dates[1], dates[2])
    end
    return query_list
end

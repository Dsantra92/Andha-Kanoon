module query

export generate_query_string, get_number_of_results_for_query, get_sub_optimal_dates

include("years.jl")
include("utils.jl")

using HTTP
using Gumbo
using Cascadia
using Dates
using .years


"""
Returns a query string for a starting date and ending date.
"""
function generate_query_string(court_id::String, start_date::Date, end_date::Date)::String
    base_url = "https://indiankanoon.org/search/?formInput=doctypes:"
    date1 = Dates.format(start_date, "d-m-Y")
    date2 = Dates.format(end_date, "d-m-Y")

    query = base_url * court_id * " "
    query *= "fromdate:" * date1 * " "
    query *= "todate:" * date2
    return query
end


"""
Returns the actual number of results from the query result.
"""
function get_number_of_results_for_query(html_query_page:: HTMLDocument)::Int
    query_info = nodeText(eachmatch(Selector("b"), html_query_page.root)[1])
    if query_info == "No matching results"
        return 0
    end

    no_of_results = parse(Int, split(query_info, " ")[5])
    return no_of_results
end

"""
Returns the actual number of results from the query.
"""
function get_number_of_results_for_query(query:: String)::Int
    return get_number_of_results_for_query(get_html(query))
end

"""
Splits the query dates into a vector of sub-optimal dates.
"""
function divide_dates(date1::Date, date2::Date, gap::Day, n_queries::Int)::Vector{Tuple{Date, Date}}
    date_list = Vector{Tuple{Date, Date}}(undef, n_queries)

    date_list[1] = (date1, date1 + gap)

    for i in range(2, n_queries-1)
        new_date = date_list[i-1][2] + Day(1)
        date_list[i] = (new_date, new_date + gap)
    end
    date_list[end] = (date_list[end-1][2] + Day(1), date2)
    return date_list
end


"""
Splits the dates into a vector of sub-optimal dates depending on the number of results. This function
expects the user to have checked the inputs before calling this function.
"""
function get_sub_optimal_dates(date1::Date, date2::Date, n_results::Int)::Vector{Tuple{Date, Date}}
    total_days = date2 - date1 + Day(1)
    # Considering the number of cases to be unifromly distributed over the total days.
    # We expect the number of cases to be less than 400 for each query.
    n_queries = Int(ceil(n_results / 400))

    # If the required no of queires are more than the total days,
    # we need to reduce the number of queries that can be made.
    # Don't mess with this code, pain in the ass to debug.
    if total_days.value < n_queries
        n_queries = total_days.value
    end

    n_days = total_days ÷ n_queries - Day(1)
    opt_dates = divide_dates(date1, date2, n_days, n_queries)
    return opt_dates
end

end
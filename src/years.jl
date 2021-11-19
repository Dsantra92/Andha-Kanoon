module years

export all_court_id_with_years

using HTTP
using Gumbo
using Cascadia
include("utils.jl")

"""
Returns the a vector of urls. Each url points to a court page listing the years for
which records are available for that court.
"""
function all_court_urls()::Vector{String}

    base_url = "https://indiankanoon.org"
    path = "/browse"
    doc = get_html(base_url * path)

    # Get the first table
    table1 = eachmatch(Selector("table"), doc.root)[1]

    # Select with proper href tag, can be regex for better performance.
    sel = "[href#=(/browse/*)]"

    hrefs = eachmatch(Selector(sel), table1)
    court_path_urls = getattr.(hrefs, "href")

    # Add with the base url for a complete link
    complete_urls = base_url .* court_path_urls
    return complete_urls
end

"""
Returns the years for which records are available for a given court url.
"""
function years_for_court(court_url:: String):: Vector{String}
    doc = get_html(court_url)

    # We need the only table present
    table = only(eachmatch(Selector("table"), doc.root))

    sel = "[href#=(/browse/*)]"
    hrefs = eachmatch(Selector(sel), table)

    # Number of entries can be 0, for eg: Lucknow
    isempty(hrefs) && return []  # Return value is subject to change

    court_year_urls = getattr.(hrefs, "href")
    years = getindex.(splitpath.(court_year_urls), 4)
    # Number can be easy choice, but we are sending string queries at the end.
    return years
end


"""
Returns a dict of all court_id pointing to a vector of years for which records are available.
"""
function all_court_id_with_years()::Dict{String, Vector{String}}
    court_urls = all_court_urls()
    years = Vector{Vector{String}}(undef, length(court_urls))

    @sync for (i, court_url) in enumerate(court_urls)
        @async years[i] = years_for_court(court_url)
    end

    # Splitting a link will give exactly 4 values
    # last one is the court id
    court_ids = getindex.(splitpath.(court_urls), 4)
    court_id_to_years = Dict(court_ids .=> years)

    return court_id_to_years
end

end
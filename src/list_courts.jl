using HTTP
using Gumbo
using Cascadia


# Retunrs the link for each Court
function get_court_links() :: Vector{String}
    base_url = "https://indiankanoon.org"
    path = "/browse"
    r = HTTP.get(base_url * path)
    doc = parsehtml(String(r.body))

    # Get the first table
    table1 = eachmatch(Selector("table"), doc.root)[1]

    # Select with proper href tag, can be regex for better performance.
    sel = "[href#=(/browse/*)]"

    hrefs = eachmatch(Selector(sel), table1)
    links = getattr.(hrefs, "href")

    # Combine the url for a complete link
    complete_links = base_url .* links
    return complete_links
end


# Returns the first year for which records are available for one court link
function get_starting_year(url:: String):: String
    r = HTTP.get(url)
    doc = parsehtml(String(r.body))

    # Even though it is the only table, we need the
    # element not a vector
    table = only(eachmatch(Selector("table"), doc.root))

    sel = "[href#=(/browse/*)]"
    hrefs = eachmatch(Selector(sel), table)
    # Number of entries can be none, for eg: Lucknow
    isempty(hrefs) && return "-1"  # Return value is subject to change

    first_year_link = getattr(hrefs[1], "href")
    # Number can be easy choice, but we are sending string queries at the end.
    return splitpath(first_year_link)[end]
end


# Get all Court codes with their starting year in string
function court_id_with_start_year()::Dict{String, String}
    court_links = get_court_links()
    years = Vector{String}(undef, length(court_links))

    @sync for (i, court_link) in enumerate(court_links)
        @async years[i] = get_starting_year(court_link)
    end

    # Splitting a link will give exactly 4 values
    # last one is the court id
    court_ids = getindex.(splitpath.(a), 4)
    court_id_with_start_year = Dict(court_ids .=> years)

    return court_id_with_start_year
end

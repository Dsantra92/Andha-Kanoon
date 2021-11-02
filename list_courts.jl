using HTTP
using Gumbo
using Cascadia


function get_court_links() :: Vector{String}
    base_url = "https://indiankanoon.org"
    path = "/browse"
    r = HTTP.get(base_url * path)
    html = String(r.body)
    doc = parsehtml(html)

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

# Returns the first year for which records are available
function get_starting_year(url:: String) :: String
    r = HTTP.get(url)
    doc = parsehtml(String(r.body))
    
    # Even though it is the only table, we need the 
    # element not a vector
    table = eachmatch(Selector("table"), doc.root)[1]
    
    sel = "[href#=(/browse/*)]"

    hrefs = eachmatch(Selector(sel), table)
    year_links = getattr.(hrefs, "href")[1]

    return splitpath(year_links)[end]
end

function courtname_with_start_year()::Vector(String)
    court_links = get_court_links()
    years = get_starting_year.(court_links)

    court_year = Dict{String, String}()
    for (link, year) in zip(court_links, years)
        court_name = splitpath(link)[end]
        court_year[courtname] = year
    end
    return court_year
end
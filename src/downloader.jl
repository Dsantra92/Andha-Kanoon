include("utils.jl")
include("query.jl")
using HTTP
using Gumbo
using Cascadia


"""
Downloads a single pdf given a url.
"""
function download_single_pdf(pdf_url::String, folder::String="pdfs", verbose::Bool=true)
    r = HTTP.get(pdf_url)
    # Time to get court name may look very small now
    # But for nearly 400 names it is clearly some 10-20s for a single court
    # with my internet at play.
    doc = parsehtml(String(r.body))
    court = nodeText(eachmatch(Selector(".docsource_main"), doc.root)[1])
    court = replace(court, " " => "_")
    title = eachmatch(Selector("title"), doc.root)[1]
    title = nodeText(title)
    # Take care of some special characters.
    title = replace(title, ","=>"", " "=>"_", "/"=>".")  # Don't replace every special character
    month, year = split(title, "_")[end-1:end]
    filename = title * ".pdf"
    filepath = joinpath([folder, court, year, month])
    if !isdir(filepath)
        mkpath(filepath)
    end
    # Download the file
    headers = ["Content-Type"=> "application/x-www-form-urlencoded"]
    r = HTTP.post(pdf_url, headers,["type=pdf"])

    open(joinpath(filepath, filename), "w") do pdf
        write(pdf, r.body)
        close(pdf)  # Closing is important
    end
    if verbose
        println("Downloaded: " * filename)
    end
end

"""
Download the pdfs for a single page for a single query.
"""
function get_all_pdf_urls_for_a_page(query_url::String)
    base_doc_url = "https://indiankanoon.org/doc/"
    doc = get_html(query_url)

    qs = eachmatch(Selector("[href#=(/docfragment/*)]"), doc.root)
    hrefs = getattr.(qs, "href")  # weired strings with search parameters
    doc_numbers = getindex.(splitpath.(hrefs), 3)
    pdf_links =  base_doc_url .* doc_numbers
    return pdf_links
end

"""
Download all the pdfs given a the url links.
"""
function download_all_pdfs(pdf_urls::Vector{String})
    @sync for url in pdf_urls
        @async download_single_pdf(url)
    end
end

"""
Given a single query url page, download all pdfs from that url.
"""
function download_all_pdfs(query_url::String)
    pdf_urls = get_all_pdf_urls_for_a_page(query_url)
    download_all_pdfs(pdf_urls)
end


"""
Download all pdfs after a optmizied query.
"""
function download_optmized_query(query::String, results::Int)
    pages = Int(ceil(results / 10))
    @sync for i in range(0, pages-1)
        query_url = query * "&pagenum=$(i)"
        # println(query_url)
        @async download_all_pdfs(query_url)
    end
end

"""
Optmiize and download all pdfs for a given query.
"""
function download_pdfs(court_id::String, date1::Date, date2::Date)
    query = generate_query(court_id, date1, date2)
    doc = get_html(query)
    n_results = get_number_of_results(doc)
    # println("$(Dates.format(date1, "d-m-Y")) and $(Dates.format(date2, "d-m-Y"))")
    # println("Results = $(n_results)")
    if n_results > 400

        # Warning for a date with more than 400 results
        if date1 == date2
            datestring = Dates.format(date1, "d-m-Y")
            @warn "No of results for $(datestring) is $(n_results) which exceeds 400. The most relevant 400 cases are downloaded."
            return download_optmized_query(query, 400)
        end
        opt_dates = get_sub_optimal_query(date1, date2, n_results)
        @sync for opt_date in opt_dates
            # println("$(Dates.format(opt_date[1], "d-m-Y")) and $(Dates.format(opt_date[2], "d-m-Y"))")
            @async download_pdfs(court_id, opt_date[1], opt_date[2])
        end
    else
        return download_optmized_query(query, n_results)
    end
end

function download_all_pdfs(court_id::String, year::String)
    date1 = Date(year, "y")
    date2 = Dates.lastdayofyear(date1)
    download_pdfs(court_id, date1, date2)
end
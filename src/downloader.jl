module downloader

export  download_all_pdfs_for_a_year

include("utils.jl")
include("query.jl")
using HTTP
using Dates
using Gumbo
using Cascadia
using .query


"""
Downloads a single pdf given a url.
"""
function download_single_pdf(pdf_url::String, folder::String="pdfs", verbose::Bool=true)

    if !isdir(folder)
        mkpath(folder)
    end

    filename = splitpath(pdf_url)[4] * ".pdf"
    filepath = joinpath(folder, filename)

    # Download the file
    headers = ["Content-Type"=> "application/x-www-form-urlencoded"]
    r = HTTP.post(pdf_url, headers,["type=pdf"])

    open(filepath, "w") do pdf
        write(pdf, r.body)
        close(pdf)  # Closing is important
    end

    if verbose
        println("Downloaded: " * filename)
    end
    return nothing
end

"""
Download the pdfs for a single page for a single query.
"""
function pdf_urls_for_a_page(query_url::String)
    base_doc_url = "https://indiankanoon.org/doc/"
    doc = get_html(query_url)

    qs = eachmatch(Selector("[href#=(/docfragment/*)]"), doc.root)
    hrefs = getattr.(qs, "href")  # weired strings with search parameters
    doc_numbers = getindex.(splitpath.(hrefs), 3)
    pdf_links =  base_doc_url .* doc_numbers
    return pdf_links
end

"""
Download all the pdfs given a the pdf urls.
"""
function download_pdfs(pdf_urls::Vector{String})
    @sync for url in pdf_urls
        @async download_single_pdf(url)
    end
end

"""
Given a single query url page, download all pdfs from that url.
"""
function download_all_pdfs(query_url::String)
    pdf_urls = pdf_urls_for_a_page(query_url)
    download_pdfs(pdf_urls)
end


"""
Download all pdfs after a optmizied query.
"""
function download_pdfs_for_optmized_query(query::String, results::Int)
    pages = Int(ceil(results / 10))
    for i in range(0, pages-1)
        query_url = query * "&pagenum=$(i)"
        # println(query_url)
        download_all_pdfs(query_url)
    end
    return nothing
end

"""
Optmiize and download all pdfs for a given query.
"""
function download_pdfs(court_id::String, date1::Date, date2::Date)
    query = generate_query_string(court_id, date1, date2)
    doc = get_html(query)
    n_results = get_number_of_results_for_query(doc)
    # println("$(Dates.format(date1, "d-m-Y")) and $(Dates.format(date2, "d-m-Y"))")
    # println("Results = $(n_results)")
    if n_results > 400

        # Warning for a date with more than 400 results
        if date1 == date2
            datestring = Dates.format(date1, "d-m-Y")
            @warn "No of results for $(datestring) is $(n_results) which exceeds 400. The most relevant 400 cases are downloaded."
            return download_optmized_query(query, 400)
        end

        opt_dates = get_sub_optimal_dates(date1, date2, n_results)
        @sync for opt_date in opt_dates
            # println("$(Dates.format(opt_date[1], "d-m-Y")) and $(Dates.format(opt_date[2], "d-m-Y"))")
            @async download_pdfs(court_id, opt_date[1], opt_date[2])
        end
    else
        return download_pdfs_for_optmized_query(query, n_results)
    end
end

function download_all_pdfs_for_a_year(court_id::String, year::String)
    date1 = Date(year, "y")
    date2 = Dates.lastdayofyear(date1)
    download_pdfs(court_id, date1, date2)
end

end
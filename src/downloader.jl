module downloader

export download_all_pdfs_for_a_year

include("utils.jl")
include("query.jl")
using HTTP
using Dates
using Gumbo
using Cascadia
using Crayons
using .query


"""
Get the path for the pdf given the url for the document.
"""
function get_pdf_path(pdf_url::String, folder::String="pdfs")::String
    r = HTTP.get(pdf_url)
    doc = parsehtml(String(r.body))
    court = nodeText(eachmatch(Selector(".docsource_main"), doc.root)[1])
    court = replace(court, " " => "_")
    title = eachmatch(Selector("title"), doc.root)[1]
    title = nodeText(title)
    # Take care of some special characters.
    title = replace(title, ","=>"", " "=>"_", "/"=>".")  # Don't replace every special character
    month, year = split(title, "_")[end-1:end]
    filename = filename = splitpath(pdf_url)[4] * ".pdf"
    filepath = joinpath([folder, court, year, month, filename])
    return filepath
end

"""
Downloads a single pdf given a url.
"""
function download_single_pdf(pdf_url::String, check::Bool=false; folder::String="pdfs")

    filepath = get_pdf_path(pdf_url, folder)
    if check && isfile(filepath)
        return nothing
    end

    file_dir = dirname(filepath)
    if !isdir(file_dir)
        mkpath(file_dir)
    end

    # Download the file
    headers = ["Content-Type"=> "application/x-www-form-urlencoded"]
    r = HTTP.post(pdf_url, headers,["type=pdf"])

    open(filepath, "w") do pdf
        write(pdf, r.body)
        close(pdf)  # Closing is important
    end

    println(Crayon(foreground=:red, bold=true), "[+] Downloaded: ", Crayon(foreground=:cyan, bold=false), filepath)
    return nothing
end


"""
Download all the pdfs given the pdf urls.
"""
function download_pdfs(pdf_urls::Vector{String}, check::Bool=false)
    @sync for url in pdf_urls
        @async download_single_pdf(url, check)
    end
end

"""
Get the urls for the query. The urls are obtained only for the queried page,
or for the first page if no page is mentioned in the query.
"""
function pdf_urls_for_query(query_url::String)
    base_doc_url = "https://indiankanoon.org/doc/"
    doc = get_html(query_url)

    qs = eachmatch(Selector("[href#=(/docfragment/*)]"), doc.root)
    hrefs = getattr.(qs, "href")  # weired strings with search parameters
    doc_numbers = getindex.(splitpath.(hrefs), 3)
    pdf_links =  base_doc_url .* doc_numbers
    return pdf_links
end

"""
Given a single query url page, download all pdfs from that url.
"""
function download_all_pdfs(query_url::String, check::Bool=false)
    pdf_urls = pdf_urls_for_query(query_url)
    download_pdfs(pdf_urls, check)
end

"""
Download all pdfs after a optmizied query. Does (should) not download more than 400 pdfs per call.
"""
function download_pdfs_for_optmized_query(query::String, results::Int, check::Bool=false)
    pages = Int(ceil(results / 10))
    @sync for i in range(0, pages-1)
        query_url = query * "&pagenum=$(i)"
        @async download_all_pdfs(query_url, check)
    end
    return nothing
end


function download_most_recent_pdfs(queries::Vector{String})
    for query in queries
        recent_query  = query * " sortby:mostrecent"
        download_pdfs_for_optmized_query(recent_query, 400, true)
    end
end

function download_least_recent_pdfs(queries::Vector{String})
    for query in queries
        least_recent_query  = query * " sortby:leastrecent"
        download_pdfs_for_optmized_query(least_recent_query, 400, true)
    end
end

function download_remaining_pdfs(queries::Vector{String})
    download_least_recent_pdfs(queries)
    download_most_recent_pdfs(queries)
end

function download_remaining_pdfs(filename::String)
    queries = readlines(filename)
    download_remaining_pdfs(queries)
end

"""
Optmiize and download all pdfs for a given query.
"""
function download_pdfs(court_id::String, date1::Date, date2::Date)
    query = generate_query_string(court_id, date1, date2)
    doc = get_html(query)

    re_download_file = "re-download.txt"

    n_results = get_number_of_results_for_query(doc)
    # println("$(Dates.format(date1, "d-m-Y")) and $(Dates.format(date2, "d-m-Y"))")
    # println("Results = $(n_results)")
    if n_results > 400

        # Warning for a date with more than 400 results
        if date1 == date2
            datestring = Dates.format(date1, "d-m-Y")
            @warn "No of results for $(datestring) is $(n_results) which exceeds 400. The most relevant 400 cases are downloaded."
            open("re-download.txt", "a") do file
                write(file, query, '\n')
                close(file)
            end
            # return download_optmized_query(query, 400)
            return
        end

        opt_dates = get_sub_optimal_dates(date1, date2, n_results)
        for opt_date in opt_dates
            # println("$(Dates.format(opt_date[1], "d-m-Y")) and $(Dates.format(opt_date[2], "d-m-Y"))")
            download_pdfs(court_id, opt_date[1], opt_date[2])
        end
    else
        return download_pdfs_for_optmized_query(query, n_results)
    end
    download_remaining_pdfs(re_download_file)
end

function download_all_pdfs_for_a_year(court_id::String, year::String)
    date1 = Date(year, "y")
    date2 = Dates.lastdayofyear(date1)
    download_pdfs(court_id, date1, date2)
end

end

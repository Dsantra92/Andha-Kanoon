module downloader

export download_all_docs_for_a_year

include("utils.jl")
include("query.jl")
include("convrerter.jl")
using HTTP
using Dates
using Gumbo
using Cascadia
using Crayons
using .query
using .converter


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
Downloads a single doc as pdf given a valid url of the doc.
"""
function download_doc_as_pdf(pdf_url::String; verbose::Bool=false, redownload::Bool=false, folder::String="pdfs")

    filepath = get_pdf_path(pdf_url, folder)
    if isfile(filepath) && !redownload
        return filepath
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
    if verbose
        println(Crayon(foreground=:red, bold=true), "[+] Downloaded: ", Crayon(foreground=:cyan, bold=false), out_path)
    end
    return filepath
end

"""
Download the doc as txt given the url of the doc.
"""
function download_doc_as_txt(doc_url::String; verbose::Bool=true, folder::String="txts")
    filepath = download_doc_as_pdf(doc_url, redownload=true)
    if isfile(filepath)
        outpath = convert_pdf_to_txt(filepath, folder)
        # rm(filepath) # Remove the pdf file
        if verbose
            println(Crayon(foreground=:red, bold=true), "[+] Downloaded: ", Crayon(foreground=:cyan, bold=false), outpath)
        end
    else
        error("PDF file not found: $filepath.")
    end
end

"""
Download all the pdfs given the pdf urls.
"""
function download_docs(pdf_urls::Vector{String})
    @sync for url in pdf_urls
        @async download_doc_as_txt(url)
    end
end

"""
Get the urls for the query. The urls are obtained only for the queried page,
or for the first page if no page is mentioned in the query.
"""
function doc_urls_for_query(query_url::String)
    base_doc_url = "https://indiankanoon.org/doc/"
    doc = get_html(query_url)

    qs = eachmatch(Selector("[href#=(/docfragment/*)]"), doc.root)
    hrefs = getattr.(qs, "href")  # weired strings with search parameters
    doc_numbers = getindex.(splitpath.(hrefs), 3)
    doc_urls =  base_doc_url .* doc_numbers
    return doc_urls
end

"""
Given a single query url page, download all pdfs from that url.
"""
function download_docs(query_url::String)
    pdf_urls = doc_urls_for_query(query_url)
    download_docs(pdf_urls)
end

"""
Download all pdfs after a optmizied query. Does (should) not download more than 400 pdfs per call.
"""
function download_docs_for_optmized_query(query::String, results::Int)
    pages = Int(ceil(results / 10))
    @sync for i in range(0, pages-1)
        query_url = query * "&pagenum=$(i)"
        @async download_docs(query_url)
    end
    return nothing
end


function download_most_recent_docs(queries::Vector{String})
    for query in queries
        recent_query  = query * " sortby:mostrecent"
        download_pdfs_for_optmized_query(recent_query, 400)
    end
end

function download_least_recent_docs(queries::Vector{String})
    for query in queries
        least_recent_query  = query * " sortby:leastrecent"
        download_pdfs_for_optmized_query(least_recent_query, 400)
    end
end

function download_remaining_docs(queries::Vector{String})
    download_least_recent_pdfs(queries)
    donload_most_recent_pdfs(queries)
end

function download_remaining_docs(filename::String)
    queries = readlines(filename)
    download_remaining_pdfs(queries)
    rm(filename)  # Delete the file after downloading
end

"""
Optmiize and download all pdfs for a given query.
"""
function download_docs(court_id::String, date1::Date, date2::Date)
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
            @warn "No of results for $(datestring) is $(n_results) which exceeds 400, all docs may not be downloaded for this case."
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
            download_docs(court_id, opt_date[1], opt_date[2])
        end
    else
        return download_docs_for_optmized_query(query, n_results)
    end
    download_remaining_docs(re_download_file)
end

function download_all_docs_for_a_year(court_id::String, year::String)
    date1 = Date(year, "y")
    date2 = Dates.lastdayofyear(date1)
    download_docs(court_id, date1, date2)
    rm("pdfs", recursive=true)
end

end

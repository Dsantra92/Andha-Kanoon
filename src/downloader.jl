include("utils.jl")
include("query.jl")
using HTTP
using Gumbo
using Cascadia

function download_single_pdf(pdf_url::String, folder::String="pdfs")
    r = HTTP.get(pdf_url)
    # Time to get court name may look very small now
    # But for nearly 400 names it is clearly some 10-20s for a single court
    # with my internet at play.
    doc = parsehtml(String(r.body))
    court = nodeText(eachmatch(Selector(".docsource_main"), doc.root)[1])
    court = replace(court, " " => "_")
    title = eachmatch(Selector("title"), doc.root)[1]
    title = nodeText(title)
    title = replace(title, ","=>"", " "=>"_")
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
end

function get_all_pdf_urls(query_url::String)
    base_doc_url = "https://indiankanoon.org/doc/"
    doc = get_html(query_url)

    qs = eachmatch(Selector("[href#=(/docfragment/*)]"), doc.root)
    hrefs = getattr.(qs, "href")  # weired strings with search parameters
    doc_numbers = getindex.(splitpath.(hrefs), 3)
    pdf_links =  base_doc_url .* doc_numbers
    return pdf_links
end

function download_all_pdfs(pdf_urls::Vector{String})
    @sync for url in pdf_urls
        @async download_single_pdf(url)
    end
end

function download_all_pdfs(query_url::String)
    pdf_urls = get_all_pdf_urls(query_url)
    download_all_pdfs(pdf_urls)
end
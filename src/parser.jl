include("list_pdf.jl")
using HTTP
using Gumbo
using Cascadia

function download_pdf(url::String)
    r = HTTP.get(url)
    doc = parsehtml(String(r.body))
    court = nodeText(eachmatch(Selector(".docsource_main"), doc.root)[1])
    court = replace(court, " " => "_")
    title = eachmatch(Selector("title"), doc.root)[1]
    title = nodeText(title)
    title = replace(title, ","=>"", " "=>"_")
    month, year = split(title, "_")[end-1:end]
    filename = title * ".pdf"
    filepath = joinpath([court, year, month])
    if !isdir(filepath)
        mkpath(filepath)
    end
    download(url, joinpath(filepath, filename))
    return court
end

function get_all_pdf_links(url::String)
    base_doc_url = "https://indiankanoon.org/doc/"
    r = HTTP.get(url)
    doc = parsehtml(String(r.body))

    qs = eachmatch(Selector("[href#=(/docfragment/*)]"), doc.root)
    hrefs = getattr.(qs, "href")  # weired strings with search parameters
    doc_numbers = getindex.(splitpath.(hrefs), 3)
    pdf_links =  base_doc_url .* doc_numbers
    return pdf_links
end

function download_all_pdfs(urls::Vector{String})
    for url in urls
        @async download_pdf(url)
    end
end

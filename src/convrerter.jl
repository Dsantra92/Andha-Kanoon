module converter

export convert_pdf_to_txt

using PDFIO

function convert_pdf_to_txt(src::String, folder::String):: String
    doc_path_vec = splitpath(splitext(src)[1])
    doc_path_vec[end] = doc_path_vec[end] * ".txt"
    doc_path_vec[1] = folder
    out_path = joinpath(doc_path_vec[1:end-1])
    out = joinpath(doc_path_vec)
    if !isdir(out_path)
        mkpath(out_path)
    end

    doc = pdDocOpen(src)
    open(out, "w") do io
        npage = pdDocGetPageCount(doc)
        for i=1:npage
            page = pdDocGetPage(doc, i)
            pdPageExtractText(io, page)
        end
    end
    pdDocClose(doc)
    return out
end

end
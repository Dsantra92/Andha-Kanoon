module converter

export convert_pdf_to_txt

using PDFIO

"""Converts the pdf file stored in path `src` to a txt file."""
function convert_pdf_to_txt(src::String, folder::String)::String

    # splitext returns a tuple of (path, ext)
    # we only want the path
    doc_path_vec = splitpath(splitext(src)[1])

    # The doc we need has extension .txt
    doc_path_vec[end] = doc_path_vec[end] * ".txt"
    # Re-direct to the new folder
    doc_path_vec[1] = folder

    # Path of the file without the filename
    out_path = joinpath(doc_path_vec[1:end-1])
    if !isdir(out_path)
        mkpath(out_path)
    end

    # Path with filename
    filepath = joinpath(doc_path_vec)

    # Convert the pdf to txt begins here
    # Shamelessly taken from https://github.com/sambitdash/PDFIO.jl#sample-code
    doc = pdDocOpen(src)
    open(filepath, "w") do io
        npage = pdDocGetPageCount(doc)
        for i=1:npage
            page = pdDocGetPage(doc, i)
            pdPageExtractText(io, page)
        end
    end
    pdDocClose(doc)
    return filepath
end

end
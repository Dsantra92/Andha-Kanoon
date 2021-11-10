include("downloader.jl")
include("years.jl")

court_id_to_years = all_court_id_with_years()

function download_all_pdf_for_all_courts(court_id_to_years)

    @sync for (court_id, year) ∈ pairs(court_id_to_years)
        if year[1] == "-1"
            continue
        else
        @async download_all_pdfs(court_id, year)
        end
    end
end

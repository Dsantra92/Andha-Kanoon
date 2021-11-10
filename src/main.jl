include("downloader.jl")
include("years.jl")


function download_all_pdf_for_all_courts()
    court_id_to_years = all_court_id_with_years()

        @sync for (court_id, years) ∈ pairs(court_id_to_years)
            if years[1] == "-1"
                continue
            else
                for year in years
                    @async download_all_pdfs_for_a_year(court_id, year)
                end
            end
        end
end

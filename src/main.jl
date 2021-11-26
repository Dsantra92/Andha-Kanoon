include("downloader.jl")
include("years.jl")

using .years
using .downloader


function download_all_docs(start_year::Int, end_year::Int)
    court_id_to_years = all_court_id_with_years()
    for (court_id, years) in pairs(court_id_to_years)
        for year in years
            if parse(Int, year) >= start_year && parse(Int, year) <= end_year
                download_all_docs_for_a_year(court_id, year)
            end
        end
    end
end

function download_all_docs_for_all_courts()
    court_id_to_years = all_court_id_with_years()

        for (court_id, years) in pairs(court_id_to_years)
            for year in years
                download_all_docs_for_a_year(court_id, year)
            end
        end
end

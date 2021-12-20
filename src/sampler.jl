module sampler

export download_sample_court_docs

using Dates
using Random:shuffle
include("query.jl")
include("downloader.jl")
using .query
using .downloader


function get_doc_urls(query::String, results::Int)::Vector{String}
    # Each page contains 10 results
    pages = ceil(Int, results / 10)
    # Always good to initialize the size before we get on the loop
    # Saves lot of gc time.
    doc_urls = Vector{Vector{String}}(undef, pages)

    @sync for i in range(0, pages-1)
        query_url_page_i = query * "&pagenum=$(i)"
        @async doc_urls[i+1] = downloader.doc_urls_for_query(query_url_page_i)
    end
    # Concat all the doc urls from all the pages into once single vector
    return vcat(doc_urls...)
end

function get_doc_urls(court_id::String, start_date::Date, end_date::Date)::Vector{String}
    query = generate_query_string(court_id, start_date, end_date)

    n_results = get_number_of_results_for_query(query)

    if n_results >  400
        if start_date == end_date
            # TODO: Write functions for including more files if needed.
            @warn "No of court hearnings for this court between the given dates is greater than 400"
            return get_doc_urls(query, 400)
        else
            # Get a list of dates between the start and end dates that might have results < 400.
            opt_dates = downloader.get_sub_optimal_dates(start_date, end_date, n_results)

            doc_urls_sp = Vector{Vector{String}}(undef, length(opt_dates))

            @sync for (i, opt_date) in enumerate(opt_dates)
                @async doc_urls_sp[i] = get_doc_urls(court_id, opt_date[1], opt_date[2])
            end
            # Return all the doc urls as a single vector
            return vcat(doc_urls_sp...)
        end
    end

    doc_urls = get_doc_urls(query, n_results)
    return doc_urls
end

function download_docs(doc_urls::Vector{String}, folder::String)
    @sync for doc_url in doc_urls
        @async downloader.download_doc_as_txt(doc_url, folder=folder)
    end
end

function download_random_docs(doc_urls::Vector{String}, n::Int, folder::String)
    if n >= length(doc_urls)
        @warn "Population size is less than or equal to sample space."
        n = length(doc_urls)
    end
    random_urls = shuffle(doc_urls)[1:n]
    download_docs(random_urls, folder)
    return nothing
end


function download_sample_court_docs(court_id::String, start_date::Date, end_date::Date, n::Int)
    doc_urls = get_doc_urls(court_id, start_date, end_date)
    download_random_docs(doc_urls, n, mktempdir("Samples";prefix="$(court_id)_", cleanup=false))
end

function download_sample_court_docs(court_id::String, start_year::String, end_year::String, n::Int)
    start_date = Date(start_year, "y")
    end_date = lastdayofyear(Date(end_year, "y"))
    download_sample_court_docs(court_id, start_date, end_date, n)
end

end
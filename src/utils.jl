using HTTP

function get_html(url::String):: HTMLDocument
    response = HTTP.get(url)
    html_body = parsehtml(String(response.body))
    return html_body
end

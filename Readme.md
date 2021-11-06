# Andha-Kanoon

This is a stateless asynchronous data scraping project using Julia. This small piece of code downloads all the pdfs available at [Indian Kanoon](https://indiankanoon.org/). As for the name of the repo, it means `Law is blind`.

<p align="center">
  <img src="misc/cover.png" width="60%">
</p>

## Why Julia?

Python is easily one of the best choices we have for data-scraping. [Beautiful Soup](https://beautiful-soup-4.readthedocs.io/en/latest/) and [Scrapy](https://scrapy.org/) are one of the well tested and popular tools out there on the internet. But these tools had one little problem: they could not bypass the Cloudflare layer without heavy external libraries. So I decided to give [Julia](https://julialang.org/) a try. These were the main reasons that convinced me:

1. Julia's speed and composability.
2. Clean and concise CSS selector [Cascadia](https://github.com/andybalholm/cascadia).
3. One of the most comprehensive async explanations in [StackOverflow](https://stackoverflow.com/a/37287021).
4. An unique library for PDFs: [PDFIO.jl](https://github.com/sambitdash/PDFIO.jl).

## What makes this data extraction a bit special?

1. The maximum number of search results per query is 400. This implies that, for a broad search, most of the documents are not downloadable or viewable from the browser. We use a variant of binary search to optimize the queries made to the server to ensure that no file is missed out.

2. Very fast. The data downloaded nearly blew up the space on my SSD once because I let it run unattended for a few minutes.

3. Light-weight and minimal dependencies.

## Further developments

- [ ] Make the proper API for extensive searching.
- [ ] More optimized and robust data scraping algorithm.
- [ ] A well documented code.

## Note to all users

The [Indian Kanoon API](https://api.indiankanoon.org/) is behind a payroll. Since data scraping is still legal, you can easily pull up a terminal and download the documents you want. Unless and until it violates or breaches any restrictions or laws enforced by the lawful owners and compilers of these documents, this repository will be available as a public repository. As the author of this code, I do not claim ownership of the data. The license for this code can be found [here](LICENSE).

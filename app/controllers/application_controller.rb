class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def reviews
    @restReviews = []

    if params[:reviews]
      @restNameParam = params[:reviews][:restName]
      @numReviewsParam = params[:reviews][:numReviews]
      if (@numReviewsParam.empty?)
        @errMsg = "Please select the number of reviews to retrieve."
        return
      end

      escapedRestName = CGI.escape(@restNameParam)
      searchURL = getNYPizzaSearchURL(escapedRestName)

      agent = Mechanize.new
      page = agent.get(searchURL)

      # find the first regular search result
      searchResult = page.search("li.regular-search-result")[0]
      if (searchResult)
        # find the Yelp link of the business then navigate to it
        restReviewsURL = searchResult.search(".biz-name")[0]['href']
        page = agent.get(restReviewsURL)
        
        # get the restaurant's name
        @restName = page.search(".biz-page-title")[0].text

        # get the reviews (review wrappers)
        # note: the first .review-wrapper is not a review,
        # it's used in the UI for the user to input their own review
        reviewWrappers = page.search(".review-wrapper")[1..@numReviewsParam.to_i]

        # get the text and stars of the reviews
        numStars = 0
        reviewWrappers.each do |rw|
          review = {}
          review['text'] = rw.search("p")[0].text
          review['stars'] = rw.search(".i-stars")[0]["title"][0].to_i
          numStars += review['stars']
          @restReviews << review
        end

        @avgStars = (numStars/@numReviewsParam.to_f).round(1)
      end
    end
  end

  def getNYPizzaSearchURL(searchTerm)
    # the URL specifies the search location to be NY and
    # search results to be related to Pizza
    return "https://www.yelp.ca/search?find_desc=#{searchTerm}&find_loc=New+York,+NY&cflt=pizza"
  end
end

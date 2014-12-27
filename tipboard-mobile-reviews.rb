# Copyright (C) 2014 Paweł Kwieciński <pawel@kwiecinski.me>
# All rights reserved.

# This software may be modified and distributed under the terms
# of the MIT license.  See the LICENSE file for details.
 

require 'rest_client'
require 'json'
require 'logging'
require 'wombat'

# CONFIGURATION CONSTANTS

## GENERAL
REVIEW_ROTATION_INTERVAL = 60
APP_STORE_FETCH_INTERVAL = 60 * 60 * 4
PLAYSTOREAPI_FETCH_INTERVAL = 60 * 60 * 4
WP_STORE_FETCH_INTERVAL = 60 * 60 * 4

## TIPBOARD
TIPBOARD_PROTOCOL = 'http'
TIPBOARD_ADDRESS = 'localhost'
TIPBOARD_PORT = '7272'
TIPBOARD_VER = 'v0.1'
TIPBOARD_KEY = 'b0b3e316b6524ac1a77abbad95a82c2a'
TIPBOARD_REQUEST_PATH = 'http://' + TIPBOARD_ADDRESS + ':' + TIPBOARD_PORT + '/api/' + TIPBOARD_VER + '/' + TIPBOARD_KEY + '/'
TIPBOARD_APP_STORE_TILE_NAME = 'text_app_reviews_apple'
TIPBOARD_GOOGLE_PLAY_TILE_NAME = 'text_app_reviews_google'
TIPBOARD_WP_STORE_TILE_NAME = 'text_app_reviews_windows'

## PLAYSTOREAPI
PLAYSTOREAPI_KEY = '0bbcd919bc817d7396e7e38f615f610f'
PLAYSTOREAPI_APP_ID = 'com.whatsapp'
PLAYSTOREAPI_FETCH_URL = 'http://api.playstoreapi.com/v1.1/apps/' + PLAYSTOREAPI_APP_ID + '?key=' + PLAYSTOREAPI_KEY

## APP STORE
APP_STORE_APP_ID = '310633997'
APP_STORE_REVIEWS_RSS_JSON_FETCH_URL = 'https://itunes.apple.com/rss/customerreviews/id=' + APP_STORE_APP_ID + '/json'

## WP STORE
WP_STORE_LOCALE = 'en-us'
WP_STORE_APP_NAME = 'whatsapp'
WP_STORE_APP_ID = '218a0ebb-1585-4c7e-a9ec-054cf4569a79'

# GLOBAL VARIABLES
$logger = Logging.logger(STDOUT)
$logger.level = :info

# CLASS DEFINITIONS
class AbsReviewFetcher
	@reviews = []

	def initialize(fetch_interval, reviews_parser)
		@last_fetch_time = Time.at(0)
		@fetch_interval = fetch_interval
		@reviews_parser = reviews_parser
	end

	def should_fetch
		return (@last_fetch_time + @fetch_interval) < Time.now
	end

	def get_reviews
		if should_fetch
			$logger.info to_s + " fetching reviews..."
			start_fetch
		else 
			$logger.debug to_s + " using cached reviews..."
		end

		return @reviews
	end

	def start_fetch
		result = fetch
		
		if result == nil
			return
		else
			$logger.debug to_s + ' fetch output: \n' + result.to_s
		end

		@reviews = @reviews_parser.parse(result)
		$logger.debug to_s + ' parse output: \n' + @reviews.inspect

		postFetch(@reviews != nil && !@reviews.empty?)
	end

	def postFetch(success)
		$logger.info to_s + " fetched reviews with result: " + success.to_s
		
		if success
			@last_fetch_time = Time.now
		end
	end

	def fetch
		raise "A subclass must implement this method"
	end
end

class HttpGetReviewFetcher < AbsReviewFetcher

	def initialize(fetch_interval, reviews_parser, fetch_url)
		super(fetch_interval, reviews_parser)

		@fetch_url = fetch_url
	end

	def fetch
		RestClient.get(@fetch_url){ |response, request, result, &block|
 			case response.code
 			when 200
 				return response
 			else
 				$logger.error to_s + ' Failed to fetch reviews. HTTP ERROR CODE: ' + response.code.to_s
 				return nil
 			end
 		}
	end

	def to_s
		return "#{HttpGetReviewFetcher.name}(#{@fetch_url})"
	end
end

class WpStoreScrapeReviewFetcher < AbsReviewFetcher
	class WpStoreWombat
		include Wombat::Crawler

  		reviews 'xpath=//*[@id="reviews"]//*[@itemprop="reviewBody"]', :list

		def initialize(locale, app_name, app_id)
			super()

			base_url "http://www.windowsphone.com"
  			path "/#{locale}/store/app/#{app_name}/#{app_id}" 
		end
	end

  	def initialize(fetch_interval, reviews_parser, locale, app_name, app_id)
  		super(fetch_interval, reviews_parser)

  		@crawler = WpStoreWombat.new(locale, app_name, app_id)
  	end

  	def fetch
  		return @crawler.crawl['reviews']
  	end

end

class AbsReviewParser
	def parse(input)
		raise "A subclass must implement this method"
	end
end

class PlayStoreApiReviewsJsonRequestParser < AbsReviewParser
	def parse(input)
		return JSON.parse(input)["topReviews"]
	end
end

class AppStoreRssJsonFeedParser < AbsReviewParser
	def parse(input)
		return JSON.parse(input)["feed"]["entry"]
	end
end

class WpStoreWombatScrapeParser < AbsReviewParser
	def parse(input)
		# Nothing has to be done, Wombat already returns read-to-use string array ;-)
		return input
	end
end

class AbsReviewsFormatter

	def initialize(reviews_array)
		@reviews_array = reviews_array
	end

	def prepareRandomReview
		raise "A subclass must implement this method"
	end

	def get_random_review
		if reviews_available
			return @reviews_array.shuffle[0]
		else
			return nil
		end
	end

	def reviews_available
		return @reviews_array != nil && !@reviews_array.empty?
	end
end

class AppStoreReviewsFormatter < AbsReviewsFormatter
	def prepareRandomReview
		if reviews_available
			review = get_random_review
			return review["title"]["label"] + "<br><br>" + review["content"]["label"]
		else
			return "ERROR: App Store reviews currently unavailable :-("
		end
	end
end

class PlayStoreReviewsFormatter < AbsReviewsFormatter
	def prepareRandomReview
		if reviews_available
			return get_random_review['reviewText']
		else
			return "ERROR: Play Store reviews currently unavailable :-("
		end
	end
end

class WindowsStoreReviewsFormatter < AbsReviewsFormatter
	def prepareRandomReview
		if reviews_available
			return get_random_review
		else
			return "ERROR: Windows Store reviews currently unavailable :-("
		end
	end
end

# FUNCTIONS
def push_data_to_tile(tile, key, data)
	RestClient.post TIPBOARD_REQUEST_PATH + 'push', :tile => tile, :key => key, :data => data.to_json
end

# VARIABLES
app_store_fetcher = HttpGetReviewFetcher.new(APP_STORE_FETCH_INTERVAL, AppStoreRssJsonFeedParser.new, APP_STORE_REVIEWS_RSS_JSON_FETCH_URL)
google_play_fetcher = HttpGetReviewFetcher.new(PLAYSTOREAPI_FETCH_INTERVAL, PlayStoreApiReviewsJsonRequestParser.new, PLAYSTOREAPI_FETCH_URL)
wp_store_fetcher = WpStoreScrapeReviewFetcher.new(WP_STORE_FETCH_INTERVAL, WpStoreWombatScrapeParser.new, WP_STORE_LOCALE, WP_STORE_APP_NAME, WP_STORE_APP_ID)

# MAIN
while true
	app_store_comment_to_show = AppStoreReviewsFormatter.new(app_store_fetcher.get_reviews).prepareRandomReview
	google_play_comment_to_show = PlayStoreReviewsFormatter.new(google_play_fetcher.get_reviews).prepareRandomReview
	wp_store_comment_to_show = WindowsStoreReviewsFormatter.new(wp_store_fetcher.get_reviews).prepareRandomReview

	$logger.info "Updating tiles..."
	push_data_to_tile 'text', TIPBOARD_APP_STORE_TILE_NAME, {:text => app_store_comment_to_show}
	push_data_to_tile 'text', TIPBOARD_GOOGLE_PLAY_TILE_NAME, {:text => google_play_comment_to_show}
	push_data_to_tile 'text', TIPBOARD_WP_STORE_TILE_NAME, {:text => wp_store_comment_to_show}
	$logger.info "Tiles updated."

	sleep REVIEW_ROTATION_INTERVAL
end
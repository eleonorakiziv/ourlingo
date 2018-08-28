require 'uri'
class ReviewsController < ApplicationController
  def index
    @user_lat = params[:search_lat]
    @user_lng = params[:search_lng]
    query = params[:input_address]

    @places = lookup(@user_lat, @user_lng, query)
    @markers = @places.map do |place|
      {
        card_id: "card_#{place['place_id']}",
        lat: place.geometry['location']['lat'],
        lng: place.geometry['location']['lng'],
        icon: ActionController::Base.helpers.asset_path('marker.png')
      }
    end
  end

  def show
    @place_id = params[:id]
    url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=#{@place_id}&fields=formatted_address,name,photos,rating,formatted_phone_number&key=#{ENV['GOOGLE_API_SERVER_KEY']}"
    place_info = HTTParty.get(url)
    @result = place_info["result"]

    @reviews = Review.where(place_id: @place_id).find_each
    @reviews.pluck(:english_rating) # sum / count
  end

  def create
    @review = Review.new(review_params)
    @place_id = @review.place_id
    @review.user = current_user
    if @review.save
      respond_to do |format|
        format.js   # <-- will render `app/views/reviews/create.js.erb`
      end
    else
      respond_to do |format|
        format.js  # <-- idem
      end
    end
  end

  def destroy
    @review = Review.find(params[:id])
    @review.destroy
  end

  private

  def review_params
    params.require(:review).permit(:content, :place_id, :english_rating)
  end

  def lookup(user_lat, user_lng, query)
    formatted_query = URI.encode(query)
    location_helper = "location=#{user_lat},#{user_lng}"
    url = "https://maps.googleapis.com/maps/api/place/textsearch/json?#{location_helper}&input=#{formatted_query}&inputtype=textquery&fields=photos,formatted_address,name,rating&key=#{ENV['GOOGLE_API_SERVER_KEY']}"
    places = HTTParty.get(url)
    @places = places["results"].map do |place|
      OpenStruct.new(place)
    end
    return @places
  end

end

require "#{Rails.root}/lib/circles_aux.rb"
require "#{Rails.root}/lib/cities_aux.rb"
require 'speech'
require 'uri'

class HomeController < ApplicationController

  def index
    @sid = params['sid']
    @cid = params['cid']

    case
    # new call
    when params && params['event'] && params['event'].downcase == "newcall"
      session[:sid] = params['sid']
      @user = User.find_by_cid(@cid)

      if !@user || @user.city.nil?   # new user
        session[:user_state] = "session_city"
        session[:city_retry_count] = 0
        session[:city_choices] = []
        @user = User.create!(:cid => params['cid'])
        circle = params['circle']
        cities_hash = CIRCLES_LIST[circle]
        @play_text = "Please "
        if(!cities_hash.blank?)
          cities_hash.each do |key, value|
            @play_text = @play_text + "press #{value} for #{key}"
            session[:city_choices] << value
          end
        else
          @play_text = @play_text + "press 1 for delhi. press 2 for kolkata.
                            press 4 for bangalore or press 7 for chennai"
          session[:city_choices] = [1, 2, 4, 7]
        end

        @play_text = @play_text + " and press #"

        respond_to do |format|
          format.any(:xml, :html) {render :template => 'home/ask_city.xml', :layout => nil, :formats => [:xml]}
        end
      else    # old user
        session[:user_state] = "session_cuisine"
        session[:city_id] = @user.city_id || "4"
        session[:retry_count] = 0
        @play_text = "Welcome to call to eat."
        @play_text = @play_text + "Please tell us your cuisine preference
                                   to search after the beep"
        respond_to do |format|
          format.any(:xml, :html) {render :template => 'home/ask_cuisine.xml', :layout => nil, :formats => [:xml]}
        end
      end
    when params && params['event'] && params['event'].downcase == 'record'     # user has entered his locality/cuisine preference
      if session[:user_state] == "session_locality"
        search_keywords = ""

        text = get_text_from_record(params['data'])
        text = get_location_from_text(text, session[:city_id])
        Rails.logger.info "SESSION2 = #{session.inspect}"

        search_keywords = text

        if search_keywords == ""
          search_keywords = "Indiranagar"
        end

        Rails.logger.info "search words = #{search_keywords}"
        hotel_details = Zomato.search_restaturants(search_keywords, session[:city_id], session[:cuisine_id])
        @play_text, @sms_message = get_formatted_text(hotel_details)
        # send_sms(@play_text)

        Rails.logger.info "sms message = #{@sms_message}"
        MESSAGE_QUEUE.push(:phone_no => params['cid'], :message => URI.encode(@sms_message))
        respond_to do |format|
          format.any(:xml, :html) {render :template => 'home/play_results.xml', :layout => nil, :formats => [:xml]}
        end
      else
        if session[:cuisine_name].nil? && session[:retry_count] == 0
          file_name = params['data'].split("/").last
          File.delete(file_name) rescue nil
        end

        #TODO: Make this async
        text = get_text_from_record(params['data'])
        puts "detected cuisines #{text.inspect}"
        cuisine_details = get_cuisine_from_text(text, session[:city_id])

        Rails.logger.info "CUISINES = #{cuisine_details.inspect}"
        cuisine_name = cuisine_details['cuisine_name']
        cuisine_id = cuisine_details['cuisine_id']

        # Retry one more time if cuisines is blank
        if cuisine_name == "" && session[:retry_count] == 0
          session[:retry_count] = 1
          @play_text = "Sorry we were unable to detect your cuisine preference. Please try again"
          respond_to do |format|
            format.any(:xml, :html) {render :template => 'home/ask_cuisine.xml', :layout => nil, :formats => [:xml]}
          end
        else
          session[:user_state] = "session_locality"    # change state to locality and get cuisine from current record
          session[:cuisine_name] = cuisine_name
          session[:cuisine_id] = cuisine_id
          Rails.logger.info "SESSION1 = #{session.inspect}"

          @play_text = "Please tell us your locality preference to search after the beep"

          respond_to do |format|
            format.any(:xml, :html) {render :template => 'home/ask_locality.xml', :layout => nil, :formats => [:xml]}
          end
        end
      end
    when params && params['event'] && params['event'].downcase == 'gotdtmf'    # user has entered his city preference
      if (params['data'] == "" && session[:city_retry_count] == 0) || (!session[:city_choices].include?(params['data'].to_i) && session[:city_retry_count] == 0)
        session[:city_retry_count] = 1
        @play_text = "Invalid city code. Please enter again."
        respond_to do |format|
          format.any(:xml, :html) {render :template => 'home/retry_asking_city.xml', :layout => nil, :formats => [:xml]}
        end
      else
        city_id = params['data'] || "4"
        city = CITIES_AUX[city_id] || 'Bangalore'
        session[:city] = city
        session[:city_id] = city_id

        @user = User.find_by_cid(params['cid'])
        @user.update_attributes!(:city => city, :city_id => city_id)

        session[:retry_count] = 0
        @play_text = "Please tell us your cuisine preference to search after the beep"
        respond_to do |format|
          format.any(:xml, :html) {render :template => 'home/ask_cuisine.xml', :layout => nil, :formats => [:xml]}
        end
      end
    else
      respond_to do |format|
        format.any(:xml, :html) {render :template => 'home/hangup.xml', :layout => nil, :formats => [:xml]}
      end
    end

  end

  def transcribe
    @sid  = params[:sid]
    @cid  = params[:cid]
    render :json =>  params
  end

  private

  def get_cuisine_from_text(texts, city_id)
    cuisine_json = RestClient.get "https://api.zomato.com/v1/cuisines.json?city_id=#{city_id}", {"X-Zomato-API-Key" => 'bee347dd88444d09a2b970adcfcb0a0a'}
    cuisines =  JSON.parse(cuisine_json)['cuisines'].collect {|cuisine| cuisine['cuisine']}
    Rails.logger.info cuisines.inspect
    texts.each do |text|
      cuisines.each do |cuisine|
        if RubyFish::DoubleMetaphone.phonetic_code(text)[0] == RubyFish::DoubleMetaphone.phonetic_code(cuisine['cuisine_name'])[0]
          Rails.logger.info text
          Rails.logger.info cuisine
          return cuisine
        end
      end
    end
    return {'cuisine_id' => "", 'cuisine_name' => ""}
  end

  def get_location_from_text(texts, city_id)
    locations_json = RestClient.get "https://api.zomato.com/v1/subzones.json?city_id=#{city_id}", {"X-Zomato-API-Key" => 'bee347dd88444d09a2b970adcfcb0a0a'}
    locations = JSON.parse(locations_json)['subzones'].collect {|location| location['subzone']['name']}
    max_length = 0
    best_location = ""
    texts.each do |text|
      locations.each do |location|
        length = subsequence(RubyFish::DoubleMetaphone.phonetic_code(text)[0], RubyFish::DoubleMetaphone.phonetic_code(location)[0])
        if length > max_length
          max_length = length
          best_location = location
        end
      end
    end
    best_location
  end

  def get_text_from_record(record)
    file_name = record.split("/").last
    while !File.exists?(file_name)
      resp = `wget #{record} | grep "200 OK"`
      sleep 1
    end
    audio = Speech::AudioToText.new(file_name)
    audio.to_text
    Rails.logger.info audio.inspect
    audio.captured_json["hypotheses"].collect {|i| i[0] }
  end

  def send_sms(text)
    @message = text
    respond_to do |format|
      format.any(:xml, :html) {render :template => 'home/send_sms.xml', :layout => nil, :formats => [:xml]}
    end
  end

  def get_formatted_text(resp)
    total_num_of_results = resp["resultsShown"]

    if total_num_of_results == 0
      reply_message = sms = "Sorry we could not find any restaurants of your choice."
      return reply_message, sms
    end

    if(total_num_of_results <=5)
      results = resp["results"]
    else
      results = resp["results"][0..4]
    end

    reply_message = "You can go to "
    sms = ""
    results.each_with_index do |result, index|
      result = result["result"]
      reply_message = reply_message + "#{result['name']} in #{result['locality']} or "

      sms = sms + "#{index+1}) #{result['name']}: #{result['address']}\n"
    end

    reply_message = reply_message[0...-3]  # remove "or " from the end of sentence
    reply_message = reply_message + ". We will be sending you all the details through sms shortly. Thank you."
    return reply_message, sms
  end

  def subsequence(s1, s2)
    return 0 if s1.empty? || s2.empty?
    num=Array.new(s1.size){Array.new(s2.size)}
    s1.scan(/./).each_with_index{|letter1,i|
      s2.scan(/./).each_with_index{|letter2,j|
        if s1[i]==s2[j]
          if i==0||j==0
             num[i][j] = 1
          else
             num[i][j]  = 1 + num[i - 1][ j - 1]
          end
        else
          if i==0 && j==0
             num[i][j] = 0
          elsif i==0 &&  j!=0  #First ith element
             num[i][j] = [0,  num[i][j - 1]].max
          elsif j==0 && i!=0  #First jth element
              num[i][j] = [0, num[i - 1][j]].max
          elsif i != 0 && j!= 0
            num[i][j] = [num[i - 1][j], num[i][j - 1]].max
          end
        end
      }
    }
    num[s1.length - 1][s2.length - 1]
  end
end

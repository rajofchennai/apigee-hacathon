require "#{Rails.root}/lib/circles_aux.rb"
require 'speech'

class HomeController < ApplicationController

  def index
    @sid = params['sid']
    @cid = params['cid']
    session[:user_state] = nil

    case
    # new call
    when params && params['event'] && params['event'].downcase == "newcall"
      session[:sid] = params['sid']
      @user = User.find_by_cid(@cid)

      if !@user || @user.city.nil?   # new user
        session[:user_state] = "session_city"
        @user = User.create!(:cid => params['cid'])
        circle = params['circle']
        cities_hash = CIRCLES_LIST[circle]
        @play_text = "Please "
        if(!cities_hash.blank?)
          cities_hash.each do |key, value|
            @play_text = @play_text + "press #{value} for #{key}"
          end
        else
          @play_text = @play_text +"press 1 for delhi press 2 for kolkata
                            press 4 for bangalore or press 7 for chennai"
        end

        @play_text = @play_text + " and press #"

        respond_to do |format|
          format.any(:xml, :html) {render :template => 'home/ask_city.xml', :layout => nil, :formats => [:xml]}
        end
      else    # old user
        session[:user_state] = "session_cuisine"
        @play_text = "Please enter your cuisine to search for restaurants"
        respond_to do |format|
          format.any(:xml, :html) {render :template => 'home/ask_cuisine.xml', :layout => nil, :formats => [:xml]}
        end
      end
    when params && params['event'] && params['event'].downcase == 'record'     # user has entered his locality/cuisine preference
      if session[:user_state] == "session_locality"
        respond_to do |format|
          format.any(:xml, :html) {render :template => 'home/send_sms.xml', :layout => nil, :formats => [:xml]}
        end
      else if session[:user_state] == "session_cuisine"
        session[:user_state] = "session_locality"    # change state to locality and get cuisine from current record
        text = get_text_from_record(params['data'])
        text = get_cuisine_from_text(text, 4)

        session[:cuisine] = text

        hotel_details = Zomato.search_restaturants(text, 4)
        @message = get_formatted_text(hotel_details)
        @play_text = "We will be sending you the list of restaurants through sms shortly"

      end
    when params && params['event'] && params['event'].downcase == 'gotdtmf'    # user has entered his city preference
      city_code = params['data']
      city = 'bangalore'
      session[:city] = city

      @user = User.find_by_cid(params['cid'])
      @user.update_attributes!(:city => city)

      @play_text = "Please tell us your cuisine preference to search for restaurants"
      respond_to do |format|
        format.any(:xml, :html) {render :template => 'home/ask_cuisine.xml', :layout => nil, :formats => [:xml]}
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
    puts params.inspect
  end

  def test
    @cid = "9535145985"
    text = "good morning"
    send_sms(text)
  end

  private

  def get_cuisine_from_text(texts, city_id)
    cuisine_json = RestClient.get "https://api.zomato.com/v1/cuisines.json?city_id=#{city_id}", {"X-Zomato-API-Key" => 'bee347dd88444d09a2b970adcfcb0a0a'}
    cuisines =  JSON.parse(cuisine_json)['cuisines'].collect {|cuisine| cuisine['cuisine']['cuisine_name']}
    texts.each do |text|
      cuisines.each do |cuisine|
        if RubyFish::DoubleMetaphone.phonetic_code(text)[0] == RubyFish::DoubleMetaphone.phonetic_code(cuisine)[0]
          return cuisine
        end
      end
    end
    return ""
  end

  def get_text_from_record(record)
    file_name = record.split("/").last
    while !File.exists?(file_name)
      resp = `wget #{record} | grep "200 OK"`
      sleep 1
    end
    audio = Speech::AudioToText.new(file_name)
    audio.to_text
    audio.captured_json["hypotheses"].collect {|i| i[0] }
  end

  def send_sms(text)
    @text = text
    respond_to do |format|
      format.any(:xml, :html) {render :template => 'home/send_sms.xml', :layout => nil, :formats => [:xml]}
    end
  end

  def get_formatted_text(json_resp)
  end
end

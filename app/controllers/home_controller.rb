require "#{Rails.root}/lib/circles_aux.rb"
require 'speech'

class HomeController < ApplicationController

  def index
    @sid = params['sid']
    @cid = params['cid']

    case
    # new call
    when params && params['event'].downcase == "newcall"
      session[:sid] = params['sid']
      @user = User.find_by_cid(@cid)

      if !@user || @user.city.nil?   # new user
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
        @play_text = "Please enter your cuisine to search for restaurants"
        respond_to do |format|
          format.any(:xml, :html) {render :template => 'home/ask_cuisine.xml', :layout => nil, :formats => [:xml]}
        end
      end
    when params && params['event'].downcase == 'record'     # user has entered his locality/cuisine preference
      text = get_text_from_record(params['event'])
      session[:cuisine] = text


    when params && params['event'].downcase == 'gotdtmf'    # user has entered his city preference
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

#     respond_to do |format|
#       format.any(:xml, :html) {render :template => 'home/index.xml', :layout => nil, :formats => [:xml]}
#     end
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
  end

  def get_text_from_record(record)
    `wget #{record}`
    audio = Speech::AudioToText.new(record)
    audio.to_text
    audio.hypotheses
  end

  def send_sms(text)
    @text = text
    respond_to do |format|
      format.any(:xml, :html) {render :template => 'home/send_sms.xml', :layout => nil, :formats => [:xml]}
    end
  end
end

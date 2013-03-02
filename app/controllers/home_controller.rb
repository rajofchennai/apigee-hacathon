require "#{Rails.root}/lib/circles_aux.rb"

class HomeController < ApplicationController

  def index
    @sid = params['sid']

    case
    # new call
    when params && params['event'].downcase == "newcall"
      session[:sid] = params['sid']
      @cid = params['cid']
      @user = User.find_by_cid(@cid)

      if !@user    # new user
        @user = User.create!(:cid => params['cid'])
        circle = params['circle']
        cities_hash = CIRCLES_LIST[circle]
        @play_text = "Please "
        if(!cities_hash.blank?)
          cities_hash.each do |key, value|
            @play_text = @play_text + "press #{value} for #{key}"
          end
        else
          @play_text = "press 1 for delhi press 2 for kolkata press 4 for bangalore
                        or press 7 for chennai"
        end

        respond_to do |format|
          format.any(:xml, :html) {render :template => 'home/ask_city.xml', :layout => nil, :formats => [:xml]}
        end
      else    # old user
        @play_text = "Please enter your cuisine to search for restaurants"
        respond_to do |format|
          format.any(:xml, :html) {render :template => 'home/ask_cuisine.xml', :layout => nil, :formats => [:xml]}
        end
      end
    when params && params['event'].downcase == 'record'     # call in session
      text = get_text_from_record(params['event'])
      session[:cuisine] = text
    when params && params['event'].downcase == 'gotdtmf'    # user has entered his city preference
      city_code = params['data']
      city = 'bangalore'
      session[:city] = city

      @user = User.find_by_cid(params['cid'])
      @user.update_attributes!(:city => city)

      @play_text = "Please enter your cuisine to search for restaurants"
      respond_to do |format|
        format.any(:xml, :html) {render :template => 'home/ask_cuisine.xml', :layout => nil, :formats => [:xml]}
      end
    end

#     respond_to do |format|
#       format.any(:xml, :html) {render :template => 'home/index.xml', :layout => nil, :formats => [:xml]}
#     end
  end

  private

  def get_text_from_record(record)
  end
end

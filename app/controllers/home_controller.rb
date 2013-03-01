class HomeController < ApplicationController

  def index
    puts params.inspect

    case
    when params && params['event'] == "NewCall"
      @user = User.find_by_cid(params['cid'])
    end

    respond_to do |format|
      format.any(:xml, :html) {render :template => 'home/index.xml', :layout => nil, :formats => [:xml]}
    end
  end
end

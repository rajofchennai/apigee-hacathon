require 'uri'
require 'rest-client'

class Zomato
  def self.search_restaturants(city_id, keywords)
    resp = RestClient.get("https://api.zomato.com/v1/search.json?city_id=#{city_id}&q=#{URI.encode(keywords)}")

    resp_body = {}
    if resp.code == 200
      resp_body = resp.body
    else
    end

    resp_body
  end
end

require 'uri'
require 'rest-client'

class Zomato
  def self.search_restaturants(keywords, city_id = 4)
    url = "https://api.zomato.com/v1/search.json?city_id=#{city_id}&q=#{URI.encode(keywords)}"
    resp = RestClient.get url, {"X-Zomato-API-Key" => 'bee347dd88444d09a2b970adcfcb0a0a'}

    resp_body = {}
    if resp.code == 200
      resp_body = JSON.parse(resp.body)
    else
    end

    resp_body
  end
end

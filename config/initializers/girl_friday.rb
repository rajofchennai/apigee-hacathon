require 'rest-client'

MESSAGE_QUEUE = GirlFriday::WorkQueue.new(:send_sms, :size => 3) do |msg|
  puts "#{msg.inspect}"
  url = "http://www.kookoo.in/outbound/outbound_sms.php?phone_no=#{msg[:phone_no]}&api_key=KKb05fc6024cdea32d87020f4ccffc85a5&message=#{msg[:message]}"

  resp = RestClient.get(url)
  puts resp.inspect
end

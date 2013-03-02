xml.instruct!
xml.tag!("Response", "sid" => @sid) do
  xml.tag!("collectdtmf", "l" => "4", "o" => "5000", "transcribe" => true, "transcribe_callback_url" => "http://voice-search-test.apigee.net/transcript") do
    xml.playtext("Hello Welcome to call to eat")
    xml.playtext(@play_text)
  end
end

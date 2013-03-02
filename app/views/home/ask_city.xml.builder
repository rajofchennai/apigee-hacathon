xml.instruct!
xml.tag!("Response", "sid" => @sid) do
  xml.tag!("collectdtmf", "l" => "4", "o" => "5000") do
    xml.playtext("Hello Welcome to call to eat")
    xml.playtext(@play_text)
  end
end

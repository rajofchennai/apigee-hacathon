xml.instruct!
xml.tag!("Response", "sid" => @sid) do
  xml.tag!("collectdtmf", "l" => "4", "o" => "5000") do
    xml.playtext(@play_text)
  end
end

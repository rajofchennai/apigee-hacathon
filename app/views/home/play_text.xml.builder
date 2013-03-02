xml.instruct!
xml.tag!("Response", "sid" => @sid, "filler" => "yes") do
  xml.playtext(@play_text)
end

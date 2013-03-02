xml.instruct!
xml.tag!("Response", "sid" => @sid) do
  xml.tag!("record", "format"="wav" "silence"="3" "maxduration"="10") do
    xml.playtext(@play_text)
  end
end

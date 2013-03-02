xml.instruct!
xml.tag!("Response", "sid" => @sid) do
  xml.playtext(@play_text)
  xml.tag!("record", "locality_#{@cid}_#{@sid}", "format" => "wav", "silence" => "3", "maxduration" => "10")
end

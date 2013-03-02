xml.instruct!
xml.tag!("Response", "sid" => @sid) do
  xml.playtext(@play_text)
  xml.tag!("sendsms", @message, "to" => @cid)
end

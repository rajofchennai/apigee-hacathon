xml.instruct!
xml.tag!("Response", "sid" => @sid) do
  xml.tag!("sendsms", @text, "to" => @cid)
end

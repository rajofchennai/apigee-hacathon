ApigeeHacathon::Application.routes.draw do
  root :to => "home#index"
  match '/transcribe', "home#transcribe"
end

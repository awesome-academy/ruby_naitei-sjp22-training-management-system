Rails.application.config.middleware.use OmniAuth::Builder do
  OmniAuth.config.allowed_request_methods =  %i(post get)
  provider :google_oauth2,
           ENV["GOOGLE_CLIENT_ID"],
           ENV["GOOGLE_CLIENT_SECRET"],
           {
             scope: "email,profile",
             prompt: "select_account",
             access_type: "online"
           }
end

OmniAuth.config.logger = Rails.logger

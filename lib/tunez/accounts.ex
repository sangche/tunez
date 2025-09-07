defmodule Tunez.Accounts do
  use Ash.Domain, otp_app: :tunez, extensions: [AshJsonApi.Domain]

  # Note: All of the AshAuthentication actions are restricted, to only be accessible via AshAuthenticationPhoenix’s form components. P.122
  # So, if you try to call the sign-in action through the JSON:API endpoint, you’ll get an error like this:
  # curl -X POST -H "Content-Type: application/json" -d '{"data": { "attributes": {"email": "value1", "password": "value2"} } }' http://localhost:4000/api/json/users/sign-in
  # {"errors":[{"code":"unacceptable_media_type","id":"f3bbc375-ec8a-4089-95fc-3e5f5e13a165","meta":{},"status":"406","title":"Unacceptable Media Type"}],"jsonapi":{"version":"1.0"}}

  json_api do
    routes do
      base_route "/users", Tunez.Accounts.User do
        post :register_with_password, route: "/register"
        post :sign_in_with_password, route: "/sign-in"
      end
    end
  end

  resources do
    resource Tunez.Accounts.Token
    resource Tunez.Accounts.User
  end
end

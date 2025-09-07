defmodule Tunez.Accounts do
  use Ash.Domain, otp_app: :tunez, extensions: [AshJsonApi.Domain]

  # Note: All of the AshAuthentication actions are restricted, to only be accessible via AshAuthenticationPhoenix’s form components. P.122
  # So, if you try to call the sign-in action through the JSON:API endpoint, you’ll get an error like this:
  # curl -X POST -H "Content-Type: application/vnd.api+json" -d '{"data": { "attributes": {"email": "value1", "password": "value2"} } }' http://localhost:4000/api/json/users/sign-in
  # {"errors":[{"code":"Forbidden","id":"f3bbc375-ec8a-4089-95fc-3e5f5e13a165","meta":{},"status":"406","title":"Unacceptable Media Type"}],"jsonapi":{"version":"1.0"}}

  json_api do
    routes do
      base_route "/users", Tunez.Accounts.User do
        post :register_with_password, route: "/register"

        # post :sign_in_with_password, route: "/sign-in"
        post :sign_in_with_password do
          route "/sign-in"

          metadata fn _subject, user, _request ->
            %{token: user.__metadata__.token}
          end
        end
      end
    end
  end

  # After policy modified in user.ex, now we can sign in:
  # curl -X POST -H "Content-Type: application/vnd.api+json" -d '{"data": { "attributes": {"email": "aaa@example.com", "password": "aaaaaaaa"} } }' http://localhost:4000/api/json/users/sign-in
  # {"data":{"attributes":{"email":"aaa@example.com"},"id":"6b62bf54-0fac-410e-9be2-30ad935dd0c4","links":{},"meta":{},"type":"user","relationships":{}},"links":{"self":"http://localhost:4000/api/json/users/sign-in"},"meta":{"token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJ-PiA0LjkiLCJleHAiOjE3NTg0NjMzNzYsImlhdCI6MTc1NzI1Mzc3NiwiaXNzIjoiQXNoQXV0aGVudGljYXRpb24gdjQuOS4zIiwianRpIjoiMzFoZzl2dWNxOTI3MDJmZ3NrMDAwMDQyIiwibmJmIjoxNzU3MjUzNzc2LCJwdXJwb3NlIjoidXNlciIsInN1YiI6InVzZXI_aWQ9NmI2MmJmNTQtMGZhYy00MTBlLTliZTItMzBhZDkzNWRkMGM0In0.lh-HATejbmktPMGWGLmPfibcHQ2AN0mQAFtH4GnDIe8"},"jsonapi":{"version":"1.0"}}

  resources do
    resource Tunez.Accounts.Token
    resource Tunez.Accounts.User
  end
end

defmodule Tunez.Accounts do
  use Ash.Domain, otp_app: :tunez, extensions: [AshJsonApi.Domain]

  resources do
    resource Tunez.Accounts.Token
    resource Tunez.Accounts.User
  end
end

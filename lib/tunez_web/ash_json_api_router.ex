defmodule TunezWeb.AshJsonApiRouter do
  use AshJsonApi.Router,
    domains: [Tunez.Music, Tunez.Accounts],
    open_api: "/open_api",
    open_api_title: "Tunez API Documentation 기본적으로는 Open API Specification",
    open_api_version: to_string(Application.spec(:tunez, :vsn))
end

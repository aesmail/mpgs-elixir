defmodule Mpgs.Session do
  def create_session(params) do
    default_session = %{"session" => %{"authenticationLimit" => 25}}
    Mpgs.Request.start_request(params, :post, "session", default_session)
  end

  def update_session(session, params) do
    Mpgs.Request.start_request(params, :put, "session/#{session}", params)
  end
end

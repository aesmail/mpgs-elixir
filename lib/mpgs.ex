defmodule Mpgs do
  @moduledoc """
  This module deals with the MasterCard Payment Gateway Service (MPGS).

  Check the MPGS API documentation for more details:

  https://ap-gateway.mastercard.com/api/documentation/apiDocumentation/rest-json/version/latest/api.html?locale=en_US
  """

  def request(options, method, path, payload \\ %{}) do
    Mpgs.Request.start_request(options, method, path, payload)
  end

  @doc """
  Returns `true` if the MPGS API is operational, `false` otherwise.

  Available map keys:
  - `api_base`. Optional. Defaults to `75`.
  - `api_version`. Optional. Defaults to `https://ap-gateway.mastercard.com/api/rest`.

  ```
  Mpgs.check_connectivity()
  true
  ```
  """
  def check_connectivity(params \\ %{}) do
    base =
      Mpgs.Parameter.get_var(
        params,
        :api_base,
        "MPGS_API_BASE",
        "https://ap-gateway.mastercard.com/api/rest"
      )

    version = Mpgs.Parameter.get_var(params, :api_version, "MPGS_API_VERSION", "75")
    url = "#{base}/#{version}/information"

    Finch.build(:get, url)
    |> Finch.request(MpgsFinch)
    |> Mpgs.Response.parse_response()
    |> then(fn
      {:ok, json} -> json["status"] == "OPERATING"
      _ -> false
    end)
  end

  def rebuild_html_form(html) do
    html
    |> String.replace(~s/target="challengeFrame"/, "")
    |> String.replace("iframe", "div")
    |> String.replace(~s/target="redirectTo3ds1Frame"/, "")
    |> then(fn content -> "<html><body>#{content}</body></html>" end)
  end
end

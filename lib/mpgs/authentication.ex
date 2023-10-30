defmodule Mpgs.Authentication do
  # defp initiate_authentication(params) do
  #   payload =
  #     %{
  #       "apiOperation" => "INITIATE_AUTHENTICATION",
  #       "session" => %{"id" => session},
  #       "order" => %{
  #         "currency" => currency
  #       },
  #       "authentication" => %{
  #         "acceptVersions" => "3DS1,3DS2",
  #         "purpose" => "PAYMENT_TRANSACTION",
  #         "channel" => "PAYER_BROWSER"
  #       }
  #     }
  #     |> Map.merge(as_is_params)
  #     |> IO.inspect(label: "initiate_authentication payload")
  #     |> Jason.encode!()

  #   Finch.build(:put, url, headers, payload)
  #   |> Finch.request(MpgsFinch)
  #   |> parse_response()
  # end
end

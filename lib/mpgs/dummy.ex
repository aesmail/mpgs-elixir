defmodule Mpgs.Dummy do
  def test_data(params \\ %{}) do
    random_number = 1_000_000 + :rand.uniform(8_000_000)

    %{
      currency: "KWD",
      full_page_redirect: true,
      amount: "5.00",
      card_number:
        Mpgs.Parameter.get_var(params, :card_number, "MPGS_CARD_NUMBER", "5123450000000008"),
      expiry_month: Mpgs.Parameter.get_var(params, :card_expiry_month, "CARD_EXPIRY_MONTH", "01"),
      expiry_year: Mpgs.Parameter.get_var(params, :card_expiry_year, "CARD_EXPIRY_YEAR", "39"),
      security_code:
        Mpgs.Parameter.get_var(params, :card_security_code, "CARD_SECURITY_CODE", "100"),
      order: Mpgs.Parameter.get_var(params, :order, "MPGS_ORDER", "ORD#{random_number}"),
      trx: Mpgs.Parameter.get_var(params, :trx, "MPGS_TRX", "TRX#{random_number}"),
      browser_agent:
        Mpgs.Parameter.get_var(
          params,
          :browser_agent,
          "MPGS_BROWSER_AGENT",
          dummy_browser_agent()
        ),
      response_url: Mpgs.Parameter.get_var(params, :response_url, "MPGS_RESPONSE_URL", nil)
    }
    |> Map.merge(params)
  end

  defp dummy_browser_agent() do
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/94.0.4606.61 Safari/537.36"
  end
end

defmodule Mpgs.Response do
  def parse_response({:ok, %Finch.Response{status: status, body: body}})
      when status in 200..299 do
    {:ok, Jason.decode!(body)}
  end

  def parse_response({:ok, %Finch.Response{body: body}}), do: {:error, Jason.decode!(body)}

  def parse_response({:error, exception}), do: {:error, exception}
end

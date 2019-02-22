defmodule Slack.JsonDecodeError do
  @moduledoc false

  defexception [:reason, :string]

  def message(%Slack.JsonDecodeError{reason: reason, string: string}) do
    "Poison could not decode string for reason: `:#{reason}`, string given:\n#{string}"
  end
end

defmodule Slack.Rtm do
  @moduledoc false

  def connect(token) do
    slack_url(token)
    |> HTTPoison.get()
    |> handle_response()
  end

  defp handle_response({:ok, %HTTPoison.Response{body: body}}) do
    module = Process.get(:json_library_module)
    case module.decode(body, keys: :atoms) do
      {:ok, %{ok: true} = json} ->
        {:ok, json}

      {:ok, %{error: reason}} ->
        {:error, "Slack API returned an error `#{reason}.\n Response: #{body}"}

      {:error, reason} ->
        {:error, %Slack.JsonDecodeError{reason: reason, string: body}}

      _ ->
        {:error, "Invalid RTM response"}
    end
  end

  defp handle_response(error), do: error

  defp slack_url(token) do
    Application.get_env(:slack, :url, "https://slack.com") <>
      "/api/rtm.connect?token=#{token}&batch_presence_aware=true&presence_sub=true"
  end
end

defmodule TripDetermination do
  @moduledoc """
  This module works in conjuntion with a formatted log object to determine the reason
  why a circuit breaker trip occured in the first place, and a log was created.

  The format of the log should be as follows:
    %{
      "current_failure_count" => "25", # string - integer
      "current_failure_count_threshold" => "50", # string - integer
      "current_failure_rate_threshold" => "0.25", # string - float value
      "gateway_type" => "AGatewayType", #string - name of gateway
      "time_stamp" => "2020-11-18T16:39:11Z", # string - datetime
      "total_active_count" => "8", # string - integer
      "unicorns" => "450" # string - integer
    }

  With a log formatted as such, this module will handle translating value types, and
  will apply logic to determine what type of trip it was:
  1. Gateway Saturation - if `total_active_count` > `unicorns`
  2. Gateway Failure Count - if `current_failure_count` > `current_failure_count_threshold`
  3. Gateway Failure Rate - if neither above conditions applies
  """
 def reason_for_trip(log) do
  cond do
    unicorn_saturation(log) >= 0.90 ->
      "Gateway Saturation"
    failure_count_exceeded(log) ->
      "Gateway Failure Count"
    true ->
      "Gateway Failure Rate"
  end
 end

 @doc """
 Finds the saturation for the gateway by determining the percentage of active unicorns
 that are being consumed by the specific gateway
 """
 defp unicorn_saturation(log) do
  active = String.to_integer(log["total_active_count"])
  unicorns = String.to_integer(log["unicorns"])

  active / unicorns
  |> Float.round(2)
 end

 @doc """
 Determines if the current failure count exceeds the failure count threshold
 """
 defp failure_count_exceeded(log) do
   String.to_integer(log["current_failure_count"]) > String.to_integer(log["current_failure_count_threshold"])
 end
end

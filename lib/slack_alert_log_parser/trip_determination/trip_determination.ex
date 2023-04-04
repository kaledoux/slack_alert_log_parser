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
  unicorn_saturation = String.to_integer(log["unicorns"]) / String.to_integer(log["total_active_cot"])
  |> Float.round(2)
  if unicorn_saturation >= 0.90 do
    "gateway_saturation"
  end
 end
end

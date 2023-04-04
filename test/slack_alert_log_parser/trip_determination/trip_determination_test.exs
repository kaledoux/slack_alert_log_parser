defmodule TripDeterminationTest do
  use ExUnit.Case
  doctest SlackAlertLogParser.TripDetermination
  alias SlackAlertLogParser.TripDetermination

  @saturation_log %{
    "current_failure_count" => "25",
    "current_failure_count_threshold" => "50",
    "current_failure_rate_threshold" => "0.25",
    "gateway_type" => "MercadoPago",
    "time_stamp" => "2020-11-18T16:39:11Z",
    "total_active_count" => "201",
    "unicorns" => "200"
  }

  @failure_count_log %{
    "current_failure_count" => "51",
    "current_failure_count_threshold" => "50",
    "current_failure_rate_threshold" => "0.25",
    "gateway_type" => "MercadoPago",
    "time_stamp" => "2020-11-18T16:39:11Z",
    "total_active_count" => "20",
    "unicorns" => "200"
  }

  @failure_rate_log %{
    "current_failure_count" => "31",
    "current_failure_count_threshold" => "50",
    "current_failure_rate_threshold" => "0.25",
    "gateway_type" => "MercadoPago",
    "time_stamp" => "2020-11-18T16:39:11Z",
    "total_active_count" => "20",
    "unicorns" => "200"
  }

  describe "reason_for_trip" do
    test "should flag saturation when active count is above unicorns" do
      assert TripDetermination.reason_for_trip(@saturation_log) == "Gateway Saturation"
    end

    test "should flag failure count when failure count is above failure count threshold" do
      assert TripDetermination.reason_for_trip(@failure_count_log) == "Gateway Failure Count"
    end

    test "should flag failure rate when neither saturation nor failure count is flagged" do
      assert TripDetermination.reason_for_trip(@failure_rate_log) == "Gateway Failure Rate"
    end
  end
end

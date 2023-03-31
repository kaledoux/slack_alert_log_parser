defmodule SlackAlertLogParserTest do
  use ExUnit.Case
  doctest SlackAlertLogParser

  # assuming this is run from the root project dir
  @test_dir "./test/test_log_directory"

  @time_stamp "2020-11-18T16:39:11Z"

  @event_log %{
    "attachments" => [
      %{
        "actions" => [
          %{
            "id" => "1",
            "style" => "primary",
            "text" => "Runbook",
            "type" => "button",
            "url" => "someURL"
          }
        ],
        "color" => "daa038",
        "fallback" => "Check our runbook for possible actions",
        "fields" => [
          %{
            "short" => false,
            "title" => "Possible Actions",
            "value" => " - Increase unicorn count (if saturated)\n - Check the gateway's status page"
          }
        ],
        "id" => 1,
        "text" => "Current Failure Rate Threshold: 0.25 \n Current Failure Count Threshold: 50 \n Current Failures:  25 \n Unicorns: 450 \n Total Active Count: 8"
      }
    ],
    "blocks" => [
      %{
        "block_id" => "qMz",
        "elements" => [
          %{
            "elements" => [
              %{
                "text" => "MercadoPagoGateway circuit has been tripped because: the gateway has had too many failures",
                "type" => "text"
              }
            ],
            "type" => "rich_text_section"
          }
        ],
        "type" => "rich_text"
      }
    ],
    "bot_id" => "BBJQNATGF",
    "subtype" => "bot_message",
    "text" => "MercadoPagoGateway circuit has been tripped because: the gateway has had too many failures",
    "ts" => "2020-11-18T16:39:11Z",
    "type" => "message",
    "username" => "Circuit Breaker"
  }

  @parsed [
    "Current Failure Rate Threshold: 0.25 ",
    " Current Failure Count Threshold: 50 ", " Current Failures:  25 ",
    " Unicorns: 450 ", " Total Active Count: 8"
  ]

  @threshold_values_map %{
    "Current Failure Count Threshold" => "50",
    "Current Failure Rate Threshold" => "0.25",
    "Current Failures" => "25",
    "Total Active Count" => "8",
    "Unicorns" => "450"
  }

  @saturated_event_log %{
    "current_failure_count" => "25",
    "current_failure_count_threshold" => "50",
    "current_failure_rate_threshold" => "0.25",
    "gateway_type" => "MercadoPago",
    "time_stamp" => "2020-11-18T16:39:11Z",
    "total_active_count" => "440",
    "unicorns" => "450"
  }

  describe "read_filtered_json_files_in_folder" do
    test "should filter out non-CB related logs" do
      filtered = SlackAlertLogParser.read_filtered_json_files_in_folder(@test_dir)
      assert length(filtered) == 1
      refute Enum.any?(filtered, fn obj ->
        String.contains?(obj["text"], "resumed operation")
      end)
    end

    test " should modify dates to be in ISO 8601 datetime format" do
      filtered = SlackAlertLogParser.read_filtered_json_files_in_folder(@test_dir)
      assert List.first(filtered)["ts"] == @time_stamp
    end

    test "should add \'threshold_values\' property to event logs" do
      filtered = SlackAlertLogParser.read_filtered_json_files_in_folder(@test_dir)
      assert Enum.all?(filtered, fn obj -> Map.get(obj, "threshold_values") end)
    end
  end

  describe "format_event_log_object" do
    test "should include requisite properties" do
      log_obj = List.first(SlackAlertLogParser.read_filtered_json_files_in_folder(@test_dir))
      formatted = SlackAlertLogParser.format_event_log_object(log_obj)

      # gateway type that caused trip
      assert Map.get(formatted, "gateway_type") == "MercadoPago"

      # time stamp
      assert Map.get(formatted, "time_stamp") == @time_stamp

      # failure count threshold data
      assert Map.get(formatted, "current_failure_count_threshold") == @threshold_values_map["Current Failure Count Threshold"]

      # failure count rate data
      assert Map.get(formatted, "current_failure_rate_threshold") == @threshold_values_map["Current Failure Rate Threshold"]

      # failure count data
      assert Map.get(formatted, "current_failure_count") == @threshold_values_map["Current Failures"]

      # total active count data
      assert Map.get(formatted, "total_active_count") == @threshold_values_map["Total Active Count"]

      # current unicorn consumption data
      assert Map.get(formatted, "unicorns") == @threshold_values_map["Unicorns"]
    end
  end

  # describe "reason_for_trip" do
  #   test "should return gateway_saturation if unicorns are saturated" do
  #     assert SlackAlertLogParser.reason_for_trip(@saturated_event_log) == "gateway_saturation"
  #   end

  # end

  describe "split_out_attachments_text_content " do
    test "should split text from first element in \'attachments\' list on \\n" do
      assert SlackAlertLogParser.split_out_attachments(@event_log) ==  @parsed
    end
  end

  describe "build_threshold_values" do
    test "should build new map with proper keys and values" do
      assert SlackAlertLogParser.build_threshold_values(@parsed) == @threshold_values_map
    end
  end

  describe "add_threshold_values_to_log" do
    test "should add new keys and values to event log obj" do
      new_log = SlackAlertLogParser.add_threshold_values_to_log(@event_log)
      assert Map.get(new_log, "threshold_values") == @threshold_values_map
    end
  end
end

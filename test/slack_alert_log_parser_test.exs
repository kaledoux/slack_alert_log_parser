defmodule SlackAlertLogParserTest do
  use ExUnit.Case
  doctest SlackAlertLogParser

  # assuming this is run from the root project dir
  @test_dir "./test/test_log_directory"

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

  describe "read_filtered_json_files_in_folder" do
    test "filters out non-CB related logs" do
      filtered = SlackAlertLogParser.read_filtered_json_files_in_folder(@test_dir)
      assert length(filtered) == 1
      refute Enum.any?(filtered, fn obj ->
        String.contains?(obj["text"], "resumed operation")
      end)
    end

    test "modifies dates to be in ISO 8601 datetime format" do
      filtered = SlackAlertLogParser.read_filtered_json_files_in_folder(@test_dir)
      assert List.first(filtered)["ts"] == "2020-11-18T16:39:11Z"
    end

    test "adds \'threshold_values\' property to event logs" do
      filtered = SlackAlertLogParser.read_filtered_json_files_in_folder(@test_dir)
      assert Enum.all?(filtered, fn obj -> Map.get(obj, "threshold_values") end)
    end
  end

  describe "split_out_attachments_text_content " do
    test "splits text from first element in \'attachments\' list on \\n" do
      assert SlackAlertLogParser.split_out_attachments(@event_log) ==  @parsed
    end
  end

  describe "build_threshold_values" do
    test "builds new map with proper keys and values" do
      assert SlackAlertLogParser.build_threshold_values(@parsed) == @threshold_values_map
    end
  end

  describe "add_threshold_values_to_log" do
    test "adds new keys and values to event log obj" do
      new_log = SlackAlertLogParser.add_threshold_values_to_log(@event_log)
      assert Map.get(new_log, "threshold_values") == @threshold_values_map
    end
  end
end

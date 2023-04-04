defmodule CSVWriterTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  require Logger
  doctest SlackAlertLogParser

  @formatted_logs [
    %{
      "current_failure_count" => "25",
      "current_failure_count_threshold" => "50",
      "current_failure_rate_threshold" => "0.25",
      "gateway_type" => "MercadoPago",
      "time_stamp" => "2020-11-18T16:39:11Z",
      "total_active_count" => "8",
      "unicorns" => "450"
    },
    %{
      "current_failure_count" => "5",
      "current_failure_count_threshold" => "50",
      "current_failure_rate_threshold" => "0.25",
      "gateway_type" => "Adyen",
      "time_stamp" => "2021-11-18T16:39:11Z",
      "total_active_count" => "450",
      "unicorns" => "450"
    }
  ]

  @csv_content "current_failure_count,current_failure_count_threshold,current_failure_rate_threshold,gateway_type,time_stamp,total_active_count,unicorns\r\n25,50,0.25,MercadoPago,2020-11-18T16:39:11Z,8,450\r\n5,50,0.25,Adyen,2021-11-18T16:39:11Z,450,450\r\n"

  @invalid_logs "invalid: expecting list of obj"

  @write_path "./test/slack_alert_log_parser/test_writes/test.csv"

  @invalid_write_path "./invalid/test/dir/"

  @file_path_error_log "[error] Failed to open CSV file from ./invalid/test/dir/. Error: enoent"

  @bad_logs_log "[error] Error formatting provided log list to CSV. Error: invalid: expecting list of obj"

  describe "write_logs_to_csv" do
    setup do
      File.write!(@write_path, "")
    end

    test "should log error when file path is invalid fails" do
      assert capture_log(fn -> CSVWriter.write_logs_to_csv(@formatted_logs, @invalid_write_path) end) =~ @file_path_error_log
    end

    test "should log error when logs are invalid" do
      assert capture_log(fn -> CSVWriter.write_logs_to_csv(@invalid_logs, @write_path) end) =~ @bad_logs_log
    end

    test "should write csv to provided directory" do
      #make sure file is empty
      contents = File.read!(@write_path)
      assert contents =~ ""

      # ensure write was success
      {:ok, success_msg} = CSVWriter.write_logs_to_csv(@formatted_logs, @write_path)
      assert success_msg == "CSV created at #{@write_path}"

      # verify csv content properly formatted
      updated_contents = File.read!(@write_path)
      assert updated_contents == @csv_content
    end
  end
end

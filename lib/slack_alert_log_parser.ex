defmodule SlackAlertLogParser do
  @moduledoc """
  Takes a given file path to the folder containing the dump of JSON files from Slack.
  Each file contains a given day's messages and should contain an array with objects
  representing each message that was sent in that channel on that day.

  The module will take the directory path, read the list of files and process each file,
  converting it into a more concise format with peritinent information that is exported to
  a CSV for further anylysis.
  """

  @doc """
  """
  def format_all_logs(folder_path) do
    with {:ok, filtered} <- SlackAlertLogParser.read_filtered_json_files_in_folder(folder_path) do
      formatted = filtered
      |> Enum.map(&SlackAlertLogParser.format_event_log_object/1)
      {:ok, formatted}
    else
      {:error, message} ->
        IO.puts message
        {:error, "failed to format all logs"}
    end
  end

  def read_filtered_json_files_in_folder(folder_path) do
    with {:ok, folder_contents} <- File.ls(folder_path)
    do
      processed = decode_files_from_json(folder_contents, folder_path)
      |> List.flatten()
      |> Enum.map(&SlackAlertLogParser.add_threshold_values_to_log/1)
      {:ok, processed}
    else
      :error -> IO.puts "Error!"
      {:error, :enoent} -> {:error, "Could not read files from #{folder_path}"}
    end
  end

  def format_event_log_object(event_log_object) do
    gateway = get_gateway_type(event_log_object)
    %{
      "gateway_type" => gateway,
      "time_stamp" => event_log_object["ts"],
      "current_failure_count_threshold" => event_log_object["threshold_values"]["Current Failure Count Threshold"],
      "current_failure_rate_threshold" => event_log_object["threshold_values"]["Current Failure Rate Threshold"],
      "current_failure_count" => event_log_object["threshold_values"]["Current Failures"],
      "total_active_count" =>  event_log_object["threshold_values"]["Total Active Count"],
      "unicorns" => event_log_object["threshold_values"]["Unicorns"]

    }
  end

  def add_threshold_values_to_log(event_log_obj) do
    threshold_values = split_out_attachments(event_log_obj)
    |> build_threshold_values
    event_log_obj = Map.put(event_log_obj, "threshold_values", threshold_values)
    event_log_obj
  end

  def split_out_attachments(event_log_obj) do
    List.first(event_log_obj["attachments"])["text"]
    |> String.split("\n", trim: true)
  end

  def build_threshold_values(threshold_strings_list) do
    Enum.reduce(threshold_strings_list, %{}, fn string, acc ->
      [k, v] = String.split(string, ":", trim: true)
      Map.put(acc, String.trim(k), String.trim(v))
    end)
  end

  defp decode_files_from_json(folder_contents, folder_path) do
    Enum.map(folder_contents, fn file_name ->
      file_path = "#{folder_path}/#{file_name}"
      {:ok, file_contents} = File.read(file_path)
      Poison.decode!(file_contents)
      |> filter_json_objects()
      |> convert_unix_timestamp()
    end)
  end

  defp get_gateway_type(event_log_object) do
    String.split(event_log_object["text"], " ", trim: true)
    |> List.first
    |> String.replace("Gateway", "")
  end

  defp filter_json_objects(json_contents) do
    Enum.filter(json_contents, fn obj ->
      obj["username"] == "Circuit Breaker" and
      obj["attachments"] != nil and
      String.contains?(obj["text"], "resumed operation") == false
    end)
  end

  defp convert_unix_timestamp(json_contents) do
    Enum.map(json_contents, fn obj ->
      ts = obj["ts"] |> String.to_float() |> trunc() |> DateTime.from_unix!(:second)
      Map.put(obj, "ts", DateTime.to_iso8601(ts))
    end)
  end

#  def reason_for_trip(log) do
#   unicorn_saturation = String.to_integer(log["unicorns"]) / String.to_integer(log["total_active_count"])
#   |> Float.round(2)
#   if unicorn_saturation >= 0.90 do
#     "gateway_saturation"
#   end
#  end

end

# file_location = IO.gets("Enter directory where Slack's JSON logs are being stored:")
# SlackAlertLogParser.read_filtered_json_files_in_folder()

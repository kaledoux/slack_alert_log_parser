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
  def read_filtered_json_files_in_folder(folder_path) do
    with {:ok, folder_contents} <- File.ls(folder_path)
    do

      processed = Enum.map(folder_contents, fn file_name ->
        file_path = "#{folder_path}/#{file_name}"
        {:ok, file_contents} = File.read(file_path)
        Poison.decode!(file_contents)
        |> filter_json_objects()
        |> convert_unix_timestamp()
      end)
      |> List.flatten()
      processed
    else
      :error -> IO.puts "Error!"
      {:error, :enoent} -> IO.puts "Could not read files from #{folder_path}"
    end
  end

  defp filter_json_objects(json_contents) do
    Enum.filter(json_contents, fn obj ->
      obj["username"] == "Circuit Breaker" and
      String.contains?(obj["text"], "resumed operation") == false
    end)
  end

  defp convert_unix_timestamp(json_contents) do
    Enum.map(json_contents, fn obj ->
      ts = obj["ts"] |> String.to_float() |> trunc() |> DateTime.from_unix!(:second)
      Map.put(obj, "ts", DateTime.to_iso8601(ts))
    end)
  end

  # a map function for the pipeline that adds a new property
  # the property will contain the extracted & parsed text values
  defp extract_trip_numbers(attachment_text) do
    # split the string, then split each substring on ":"
    # take the first portion of the split string and use it as a key
    # use the number (converted from string) as the value
    # add new object?
    String.split(attachment_text, "\n")
      |> Enum.map(fn sub -> String.trim(sub) end)
  end
end

# file_location = IO.gets("Enter directory where Slack's JSON logs are being stored:")
# SlackAlertLogParser.read_filtered_json_files_in_folder()

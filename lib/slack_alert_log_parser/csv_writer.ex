defmodule CSVWriter do
  require Logger
  require CSV

  def write_logs_to_csv(log_list, file_path) do
    try do
      file = File.open!(file_path, [:write, :utf8])
      log_list
      |> CSV.encode(headers: true)
      |> Enum.each(&IO.write(file, &1))

      {:ok, "CSV created at #{file_path}"}
    rescue
      e in File.Error ->
        Logger.error("Failed to open CSV file from #{file_path}. Error: #{e.reason}")
        {:error, "Error opening file path"}
      e in Protocol.UndefinedError ->
        Logger.error("Error formatting provided log list to CSV. Error: #{e.value}")
        {:error, "Error formatting provided logs"}
      _ ->
        Logger.error("Unknown error writing log list to CSV from CSVWrite.write_logs_to_csv")
        {:error, "Unknown error. Check Logs."}
    end
  end

end

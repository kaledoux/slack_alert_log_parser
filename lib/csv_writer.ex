defmodule CSVWriter do
  require Logger
  require CSV

  def write_logs_to_csv(log_list, file_path) do
    try do
      file = File.open!(file_path, [:write, :utf8])
      log_list
      |> CSV.encode(headers: true)
      |> Enum.each(&IO.write(file, &1))
    rescue
      exception ->
        Logger.error("Failed to write CSV file. Error: #{exception}")
    end
  end
end

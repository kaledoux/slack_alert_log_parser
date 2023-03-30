defmodule SlackAlertLogParserTest do
  use ExUnit.Case
  doctest SlackAlertLogParser

  test "greets the world" do
    assert SlackAlertLogParser.hello() == :world
  end
end

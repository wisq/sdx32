defmodule Sdx32.Parameters.ArgsFromEnvTest do
  use ExUnit.Case

  alias Sdx32.Parameters.ArgsFromEnv

  @input [
    "-port 28196",
    "-pluginUUID CBD4A9C8D4DA1B03D7D472EE7CF6F48A",
    "-registerEvent registerPlugin",
    ~S'-info "{\"application\":{\"font\":\"Segoe UI\",\"language\":\"en\",\"platform\":\"windows\",\"platformVersion\":\"10.0.19045\",\"version\":\"6.6.0.20583\"},\"colors\":{\"buttonMouseOverBackgroundColor\":\"#464646FF\",\"buttonPressedBackgroundColor\":\"#303030FF\",\"buttonPressedBorderColor\":\"#646464FF\",\"buttonPressedTextColor\":\"#969696FF\",\"highlightColor\":\"#0078FFFF\"},\"devicePixelRatio\":1,\"devices\":[{\"id\":\"F896E7915F27940F6BF82B73497FB3D9\",\"name\":\"Stream Deck +\",\"size\":{\"columns\":4,\"rows\":2},\"type\":7}],\"plugin\":{\"uuid\":\"net.wisq.sdx32\",\"version\":\"0.0.1\"}}"'
  ]

  @output [
    ["-port", "28196"],
    ["-pluginUUID", "CBD4A9C8D4DA1B03D7D472EE7CF6F48A"],
    ["-registerEvent", "registerPlugin"],
    [
      "-info",
      "{\"application\":{\"font\":\"Segoe UI\",\"language\":\"en\",\"platform\":\"windows\",\"platformVersion\":\"10.0.19045\",\"version\":\"6.6.0.20583\"},\"colors\":{\"buttonMouseOverBackgroundColor\":\"#464646FF\",\"buttonPressedBackgroundColor\":\"#303030FF\",\"buttonPressedBorderColor\":\"#646464FF\",\"buttonPressedTextColor\":\"#969696FF\",\"highlightColor\":\"#0078FFFF\"},\"devicePixelRatio\":1,\"devices\":[{\"id\":\"F896E7915F27940F6BF82B73497FB3D9\",\"name\":\"Stream Deck +\",\"size\":{\"columns\":4,\"rows\":2},\"type\":7}],\"plugin\":{\"uuid\":\"net.wisq.sdx32\",\"version\":\"0.0.1\"}}"
    ]
  ]

  test "parses example command line in normal order" do
    assert @input
           |> Enum.join(" ")
           |> ArgsFromEnv.parse() ==
             @output
             |> List.flatten()
  end

  test "parses example command line in random order" do
    {input, output} =
      Enum.zip(@input, @output)
      |> Enum.shuffle()
      |> Enum.unzip()

    assert input
           |> Enum.join(" ")
           |> ArgsFromEnv.parse() ==
             output
             |> List.flatten()
  end

  test "throws error on unbalanced quotes" do
    message = "Expected closing quote, reached end of arguments"

    assert_raise(RuntimeError, message, fn ->
      ~s{-info "unbalanced quote}
      |> ArgsFromEnv.parse()
    end)

    assert_raise(RuntimeError, message, fn ->
      ~s{-info "multiple "unbalanced" quotes}
      |> ArgsFromEnv.parse()
    end)

    assert ~s{-info "multiple "quotes", but balanced"} |> ArgsFromEnv.parse() ==
             ["-info", "multiple quotes, but balanced"]
  end
end

defmodule Sdx32.Parameters.ArgsFromEnv do
  @moduledoc """
  Windows batch files are fucking terrible.

  I seem to get the `-info` JSON as multiple arguments, split on spaces,
  with unbalanced quotes (since the "first" -info arg starts with a quote,
  and the "last" -info arg ends with it).

  There does not seem to be any way to even iterate through and combine those
  arguments, because even a simple `if "%1"==""` loop (using `shift`) barfs
  when it encounters those unbalanced quotes.

  So I'm just giving up, and throwing all the args (`%*`) in an env var, and
  using a sane parser (i.e. this module) to split them back out again.
  """

  def parse(nil), do: []

  def parse(argstr) do
    {arg, rest} = until_space(argstr, false)
    [Enum.join(arg) | parse(rest)]
  end

  defp until_space(argstr, in_quote) do
    case Regex.run(~r{^(.*?)(\\.|"| )(.*)$}, argstr) do
      [_, before, "\\" <> char, aftr] ->
        {arg, rest} = until_space(aftr, in_quote)
        {[before, char | arg], rest}

      [_, before, "\"", aftr] ->
        {arg, rest} = until_space(aftr, !in_quote)
        {[before | arg], rest}

      [_, before, " ", aftr] ->
        if in_quote do
          {arg, rest} = until_space(aftr, in_quote)
          {[before, " " | arg], rest}
        else
          {[before], aftr}
        end

      nil ->
        {[argstr], nil}
    end
  end
end

@echo off

set script=%0
rem See Sdx32.Parameters.ArgsFromEnv for details.
set SDX32_ARGS=%*

if exist windows\bin\sdx32.bat (
	rem Production / release mode.
	windows\bin\sdx32.bat eval "Sdx32.run()" -argsFromEnv SDX32_ARGS
) else (
	if exist mix.exs (
		rem Development mode.  
		rem Write params to file, to be picked up by `iex -S mix` later.
		set MIX_ENV=dev
		mix sdx32.dev -argsFromEnv SDX32_ARGS
	) else (
		echo %script%: Can't determine what mode I'm running in!
		exit 1
	)
)

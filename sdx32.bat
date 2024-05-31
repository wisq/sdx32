@echo off

set script=%0

:parse_args
if "%1"=="" goto run
if "%1"=="-port" (set SDX32_PORT=%2&& goto next_arg)
if "%1"=="-pluginUUID" (set SDX32_PLUGIN_UUID=%2&& goto next_arg)
if "%1"=="-registerEvent" (set SDX32_REGISTER_EVENT=%2&& goto next_arg)
if "%1"=="-info" (set SDX32_INFO=%2&& goto next_arg)

echo "Unknown argument: %1"
exit /B 1

:next_arg
shift
shift
goto parse_args

:run

if exist windows\bin\sdx32.bat (
	rem Production / release mode.
	windows\bin\sdx32.bat eval Sdx32.run()
) else (
	if exist mix.exs (
		rem Development mode.  
		rem Write params to file, to be picked up by `iex -S mix` later.
		set MIX_ENV=dev
		mix sdx32.dev
	) else (
		echo %script%: Can't determine what mode I'm running in!
		exit 1
	)
)

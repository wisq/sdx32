#!/bin/sh

while [ $# -gt 0 ]; do
	case "$1" in
		-port)
			export SDX32_PORT="$2"
			;;

		-pluginUUID)
			export SDX32_PLUGIN_UUID="$2"
			;;

		-registerEvent)
			export SDX32_REGISTER_EVENT="$2"
			;;

		-info)
			export SDX32_INFO="$2"
			;;

		*)
			echo "Unknown argument: $1" 1>&2
			exit 1
			;;
	esac
	shift
	shift
done

if [ -x macos/bin/sdx32 ]; then
	# Production / release mode.
	exec macos/bin/sdx32 eval 'Sdx32.run()'
elif [ -f mix.exs ]; then
	# Development mode.  
	# Write params to file, to be picked up by `iex -S mix` later.
	export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin
	export MIX_ENV=dev
	exec mix sdx32.dev
else
	echo "$0: Can't determine what mode I'm running in!"
	exit 1
fi

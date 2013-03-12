# This script is only meant for interactive shells.
[[ -z $PS1 ]] && return

## SETTINGS ##
shopt -s extglob
CDPATH=:~/Projects
export VISUAL=vim
[[ -f /etc/bash_completion ]] && . /etc/bash_completion

## ALIASES ##

# Makes the Debian/Ubuntu apache2 management scripts work on my personal installation.
# Example: a2user apache2ctl start
alias 'a2user=APACHE_CONFDIR=~/.apache2 APACHE_ULIMIT_MAX_FILES=true'

# Prevents the disaster 'cp *' or 'mv *' can cause...
alias 'cp=cp -i'
alias 'mv=mv -i'

# See COMMANDS section below.
alias 'cd..=c~'

## COMMANDS ##

# Sets the working directory to the specified directory entry's parent.
cdd()
{
	local opt args=() dir=

	# Pass some options through to cd.
	OPTIND=1
	while getopts LPe opt; do
		case "$opt" in
			[LPe])
				args+=("-$opt")
				;;
			\?)
				return 1
		esac
	done

	shift $((OPTIND - 1))

	# Handle a missing dir argument.
	if (( $# < 1 )); then
		cd "${args[@]}"
		return
	fi

	# Strip the final component from the path.
	# This is similar to dirname yet uses only built-in commands.
	[[ $1 == */* ]] && dir="${1%/*}/"

	# Execute the cd command.
	cd "${args[@]}" "$dir"
}

# Changes to an ancestor directory.
c~()
{
	local x
	if [[ -z $1 ]]; then
		cd ..
		return
	fi

	for (( x = 0; x < $1; x++ )); do
		cd .. || return
	done
}

# Searches source code for a line matching the specified regex.
# Example: greptree '*.php' -i 'sprintf'
greptree()
{
	grep -rHn --include="$@" .
}

# Starts or stops a local rendering server for the MediaWiki Collection extension.
mwlibserver() {
	local srvroot="$HOME/.mwlibserver"
	case "$1" in
		start)
			(cd "$srvroot"
				(setsid nserve <&- >> log/nserve.txt 2>&1 &)
				(setsid mw-qserve <&- >> log/mw-qserve.txt 2>&1 &)
				(setsid nslave --cachedir cache <&- >> log/nslave.txt 2>&1 &)
				(setsid postman <&- >> log/postman.txt 2>&1 &)
			)
			;;
		stop)
			killall -u "$USER" nserve
			killall -u "$USER" mw-qserve
		        killall -u "$USER" nslave
			killall -u "$USER" postman
			;;
		force-reload|restart)
			mwlibserver stop
			mwlibserver start
			;;
		*)
			echo "Usage: mwlibserver {start|stop}"
			return 1
			;;
	esac
	return 0
}

## PROMPT COMMANDS ##

setaf_3="$(tput setaf 3)"
sgr0="$(tput sgr0)"

ORIG_PS1="\n${debian_chroot:+($debian_chroot)}\u@\h:\w\$ "

# Inserts git information into the prompt.
rcpc_git()
{
	local repoToplevel="$(git rev-parse --show-toplevel 2>/dev/null)"

	[[ -n $repoToplevel ]] || return 1

	local friendlyRepoToplevel="${repoToplevel/#"$HOME"/~}" pathWithinRepo="${PWD#"$repoToplevel"}"
	local branch="$(git symbolic-ref HEAD 2>/dev/null)"

	[[ -z $branch ]] && branch="detached: $(git name-rev --name-only --always HEAD 2>/dev/null)"

	local formattedPath="\[$setaf_3\]$friendlyRepoToplevel\[$sgr0\]$pathWithinRepo (${branch##refs/heads/})"
	PS1="\n${debian_chroot:+($debian_chroot)}\u@\h:$formattedPath\$ "
}

PROMPT_COMMAND='rcpc_git || PS1="$ORIG_PS1"'

## COMMAND-NOT-FOUND HANDLER ##

command_not_found_handle()
{
	local i n x

	# Repeats a command (e.g. 100x repeats a command 100 times).
	if [[ $1 =~ ^[0-9]+x$ ]]; then
		(( n = 10#${1%x} ))
		shift
		for (( x = 0; x < n; x++ )); do
			"$@"
		done
		return
	fi

	if [[ -x /usr/lib/command-not-found ]]; then
		/usr/lib/command-not-found -- "$1"
		return
	fi

	printf "%s: command not found\n" "$1" >&2
	return 127
}

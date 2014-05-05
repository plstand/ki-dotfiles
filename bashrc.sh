# This script is only meant for interactive shells.
[[ -z $PS1 ]] && return

## SETTINGS ##
shopt -s extglob
export VISUAL=vim
PS1="\n$PS1"
unset command_not_found_handle

pp=~/Projects

## ALIASES ##

# Makes the Debian/Ubuntu apache2 management scripts work on my personal installation.
# Example: a2user apache2ctl start
alias 'a2user=APACHE_CONFDIR=~/.apache2 APACHE_ULIMIT_MAX_FILES=true'

# Prevents the disaster 'cp *' or 'mv *' can cause...
alias 'cp=cp -i'
alias 'mv=mv -i'

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


## PROMPT COMMANDS ##

ORIG_PS1="$PS1"
PROMPT_COMMAND=prenable

prenable()
{
	echo 'Prompt command will be enabled for next command line'
	echo 'To disable prompt command, use prdisable'
	PROMPT_COMMAND='_kdf_gitprompt || PS1="$ORIG_PS1"'
}

prdisable()
{
	unset PROMPT_COMMAND
	PS1="$ORIG_PS1"
}

# Inserts git information into the prompt.
_kdf_gitprompt()
{
	local repoToplevel="$(git rev-parse --show-toplevel 2>/dev/null)"

	[[ -n $repoToplevel ]] || return 1

	local friendlyRepoToplevel="${repoToplevel/#"$HOME"/~}" pathWithinRepo="${PWD#"$repoToplevel"}"
	local branch="$(git symbolic-ref HEAD 2>/dev/null)"

	[[ -z $branch ]] && branch="detached: $(git name-rev --name-only --always HEAD 2>/dev/null)"

	local setaf_3=$'\e[33m' sgr0=$'\e(B\e[m'
	PS1="${ORIG_PS1/\\w/\\[$setaf_3\\]$friendlyRepoToplevel\\[$sgr0\\]$pathWithinRepo (${branch##refs/heads/})}"
}

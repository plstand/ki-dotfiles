#!/bin/bash

# This script is only meant for interactive shells.
[[ $- = *i* ]] || return

declare debian_chroot

## SETTINGS ##
shopt -s histappend
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
PS1='\n${debian_chroot:+($debian_chroot)}\u@\h:\w\[\e[m\]\$ '
TITLE='\u@\h: \w'

export VISUAL=vim

# Enable colorized output for ls, etc.
if [[ -x /usr/bin/dircolors ]]; then
	eval "$(dircolors -b)"
	alias ls='ls --color=auto'
	alias dir='dir --color=auto'
	alias vdir='vdir --color=auto'
	alias grep='grep --color=auto'
	alias fgrep='fgrep --color=auto'
	alias egrep='egrep --color=auto'
	alias diff='diff --color=auto'
fi

# Enable bash-completion
if ! shopt -oq posix; then
	if [[ -f /usr/share/bash-completion/bash_completion ]]; then
		. /usr/share/bash-completion/bash_completion
	fi
fi

# Detect color support
if [[ -x /usr/bin/tput ]] && tput setaf 1 > /dev/null 2>&1; then
	KDF_USE_COLOR=1
fi

## ALIASES ##

# Prevents the disaster 'cp *' or 'mv *' can cause...
alias cp='cp -i'
alias mv='mv -i'

## COMMANDS ##

# Sets the working directory to the specified directory entry's parent.
cdd()
{
	local opt args=() dir=

	# Pass some options through to cd.
	OPTIND=1
	while getopts LPe@ opt; do
		case "$opt" in
			[LPe@])
				args+=("-$opt")
				;;
			\?)
				return 1
		esac
	done

	shift $((OPTIND - 1))

	# Handle a missing dir argument.
	if (( $# < 1 )); then
		cd "${args[@]}" || return
		return
	fi

	# Strip the final component from the path.
	# This is similar to dirname yet uses only built-in commands.
	[[ $1 == */* ]] && dir="${1%/*}/"

	# Execute the cd command.
	cd "${args[@]}" "$dir" || return
}

# Changes to an ancestor directory.
cd..()
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

# Change the working directory to the ancestor that is the specified
# number of levels above the root. If the number of levels is not
# specified as a command-line argument, it is prompted for.
# Example: up 3
up()
{
	local choice chosen=0
	if (( $# >= 1 )); then
		choice="$1"
		chosen=1
	fi

	local after="$PWD/" comp i=0
	while [[ "$after" = */* ]]; do
		comp="${after%%/*}"
		after="${after#*/}"
		if (( chosen != 0 )); then
			: # no output
		elif (( KDF_USE_COLOR )); then
			printf '\e[91m[%s] \e[m%s/ ' "$i" "$comp"
		else
			printf '[%s] %s/ ' "$i" "$comp"
		fi
		((++i))
	done
	if (( chosen == 0 )); then
		printf '\n'
	fi

	until (( chosen == 2 )); do
		if (( chosen == 0 )); then
			read -rep 'Which directory? ' choice || return
		fi

		if [[ $choice =~ ^[0-9]+$ ]] && (( choice < i )); then
			chosen=2
		else
			echo 'up: invalid selection' >&2
			(( chosen == 0 )) || return
		fi
	done

	local relpath=
	while (( --i > choice )); do
		relpath="$relpath../"
	done
	cd "$relpath" || return
}

# Searches source code for a line matching the specified regex.
# Example: greptree '*.php' -i 'sprintf'
greptree()
{
	# "grep" may expand to "grep --color=auto"
	grep -rHn --exclude-dir=.git --include="$1" "${@:2}" .
}

## PROMPT COMMANDS ##

__kdf_gitprompt_colorize_pwd()
{
	local repo_info
	repo_info="$(git rev-parse --is-inside-work-tree \
		--show-toplevel 2>/dev/null)" || return

	local toplevel="${repo_info##*$'\n'}"
	local inside_worktree="${repo_info%$'\n'*}"

	if [[ $inside_worktree != true ]]; then
		return
	fi

	# Split $PWD into "repo" and "path" parts, in a way that
	# works even in the presence of symlinks
	local repopart="$PWD" pathpart=
	# shellcheck disable=SC2030
	eval "$(
		exec 2>/dev/null
		while cd .. && [[ $(pwd -P)/ = "$toplevel"/* ]]; do
			pathpart="/${repopart##*/}$pathpart"
			repopart="${repopart%/*}"
		done
		declare -p repopart pathpart
	)"

	# Abbreviate $HOME as ~
	# shellcheck disable=SC2031,SC2034
	{
		__kdf_gitprompt_repopart="${repopart/#"$HOME/"/"~/"}"
		__kdf_gitprompt_pathpart="$pathpart"
	}

	# Build the string to insert into PS1
	# shellcheck disable=SC2016
	__kdf_gitprompt_pwd='\[\e[33m\]${__kdf_gitprompt_repopart}\[\e[m\]${__kdf_gitprompt_pathpart}'
}

__kdf_prompt_command()
{
	# Tell gnome-terminal the current working directory
	(( KDF_USE_VTE )) && __vte_osc7

	# Set the title of the terminal window
	case "$TERM" in
		xterm*|rxvt*)
			printf '\e]0;%s\a' "${TITLE@P}"
			;;
	esac

	# Add git information to the prompt
	if (( KDF_USE_GIT_SH_PROMPT )) &&
		__git_ps1 '' '' && [[ -n $PS1 ]]
	then
		__kdf_gitprompt_pwd='\w'
		if (( KDF_USE_COLOR )); then
			__kdf_gitprompt_colorize_pwd
		fi
		PS1="${ORIG_PS1/\\w/"$__kdf_gitprompt_pwd$PS1"}"
	else
		PS1="$ORIG_PS1"
	fi
}

if [[ -e /etc/profile.d/vte-2.91.sh ]]; then
	. /etc/profile.d/vte-2.91.sh
	declare -F __vte_osc7 > /dev/null && KDF_USE_VTE=1
fi

if [[ -e /usr/lib/git-core/git-sh-prompt ]]; then
	. /usr/lib/git-core/git-sh-prompt
	GIT_PS1_DESCRIBE_STYLE=branch
	KDF_USE_GIT_SH_PROMPT=1
fi

ORIG_PS1="$PS1"
PROMPT_COMMAND=__kdf_prompt_command

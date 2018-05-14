# This script is only meant for interactive shells.
[[ $- = *i* ]] || return

## SETTINGS ##
shopt -s histappend
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
PS1='\n${debian_chroot:+($debian_chroot)}\u@\h:\w\[\e[m\]\$ '

export VISUAL=vim

# Set the title of the terminal window
ORIG_PS1="$PS1"
case "$TERM" in
	xterm*|rxvt*)
		ORIG_PS1_PREFIX='\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]'
		;;
	*)
		ORIG_PS1_PREFIX=
		;;
esac
PS1="$ORIG_PS1_PREFIX$ORIG_PS1"

# Enable colorized output for ls
if [[ -x /usr/bin/dircolors ]]; then
	eval "$(dircolors -b)"
	alias ls='ls --color=auto'
fi

# Enable bash-completion
if ! shopt -oq posix; then
	if [[ -f /usr/share/bash-completion/bash_completion ]]; then
		. /usr/share/bash-completion/bash_completion
	fi
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

if [[ -x /usr/bin/tput ]] && tput setaf 1 > /dev/null 2>&1; then
	KDF_COLOR_SUPPORTED=yes
else
	KDF_COLOR_SUPPORTED=
fi

__kdf_gitprompt_colorize_pwd()
{
	local repo_info="$(git rev-parse --is-inside-work-tree \
		--show-toplevel 2>/dev/null)"

	local toplevel="${repo_info##*$'\n'}"
	local inside_worktree="${repo_info%$'\n'*}"

	if [[ $inside_worktree != true ]]; then
		return
	fi

	# Split $PWD into "repo" and "path" parts, in a way that
	# works even in the presence of symlinks
	eval "$(
		exec 2>/dev/null
		local repopart="$PWD" pathpart=
		while cd .. && [[ $(pwd -P)/ = "$toplevel"/* ]]; do
			pathpart="/${repopart##*/}$pathpart"
			repopart="${repopart%/*}"
		done
		printf 'local repopart=%q pathpart=%q' "$repopart" "$pathpart"
	)"

	# Abbreviate $HOME as ~
	__kdf_gitprompt_repopart="${repopart/#"$HOME/"/"~/"}"
	__kdf_gitprompt_pathpart="$pathpart"

	# Build the string to insert into PS1
	__kdf_gitprompt_pwd='\[\e[33m\]${__kdf_gitprompt_repopart}\[\e[m\]${__kdf_gitprompt_pathpart}'
}

__kdf_prompt_command()
{
	__git_ps1 '' ''
	if [[ -z $PS1 ]]; then
		PS1="$ORIG_PS1_PREFIX$ORIG_PS1"
		return
	fi

	__kdf_gitprompt_pwd='\w'
	if [[ $KDF_COLOR_SUPPORTED = yes ]]; then
		__kdf_gitprompt_colorize_pwd
	fi
	PS1="$ORIG_PS1_PREFIX${ORIG_PS1/\\w/"$__kdf_gitprompt_pwd$PS1"}"
}

if [[ -e /usr/lib/git-core/git-sh-prompt ]]; then
	. /usr/lib/git-core/git-sh-prompt
	GIT_PS1_DESCRIBE_STYLE=branch
	PROMPT_COMMAND=__kdf_prompt_command
fi

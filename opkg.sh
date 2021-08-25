#!/usr/bin/env bash

packages() {
	opkg list | awk '!/^ /  {print $1 }'
}

trace() {
	exec 2>/dev/pts/1
#	set -x
	echo -e "\033[36m$1\033[m=\033[1;37m'$(eval echo $1)'\033[m" >&2
#	set +x
	exec 2>$(tty)
}

_opkg() {
    # COMP_WORDS: an array of all the words typed after the
    #    name of the program the compspec belongs to
    # COMP_CWORD: an index of the COMP_WORDS array pointing
    #    to the word the current cursor is at - in other words,
    #    the index of the word the cursor was when the tab key was pressed

	trace '${COMP_WORDS[@]}'

	local COMMANDS=(help update upgrade install configure remove clean flag)
	local COMMANDS+=(list list-installed list-upgradable list-changed-conffiles)
	local COMMANDS+=(files search find info status download compare-versions)
	local COMMANDS+=(print-architecture depends whatdepends whatdependsrec)
	local COMMANDS+=(whatrecommends whatsuggests whatprovides whatconflicts whatreplaces verify)

	local LONG_OPTS=(verbosity= conf cache-dir tmp-dir lists-dir dest offline-root)
	local LONG_OPTS+=(add-dest add-arch add-exclude add-ignore-recommends prefer-arch-to-version combine fields short-description size)
	local LONG_OPTS+=(noaction download-only nodeps no-install-recommends autoremove host-cache-dir volatile-cache)

	local SHORT_OPTS=(A V f d l o t)

	local current="${COMP_WORDS[$COMP_CWORD]}"
	trace '$current'


	local command

	###

	for w in "${!COMP_WORDS[@]}"
	do
		if [[ " ${COMMANDS[*]} " =~ " ${COMP_WORDS[$w]} " ]]; then
			command="${COMP_WORDS[$w]}"
			at=$w
			break;
		fi
	done

	declare -A opts=(
		[list]="--size --short-description"
		[install]="--force-maintainer --force-reinstall --force-overwrite --force-downgrade --force-space --force-postinstall --force-checksum --download-only --no-install-recommends"
		[remove]="--force-remove --force-removal-of-dependent-packages --autoremove"
		[install-remove]="--force-depends --noaction --nodeps"
	)

if [[ -n "$command" ]]; then
	case "$command" in
	flag)
		if [[ $(($at + 1)) -eq $COMP_CWORD ]]; then
			opts="hold noprune user ok installed unpacked"
		else
			opts="$(packages)"
		fi
		;;
	list)
		opts="${opts[list]}"
		;;
	install)
		opts="${opts[install]} ${opts[install-remove]} $(packages)"
		;;
	remove)
		opts="${opts[remove]} ${opts[install-remove]} $(packages)"
		;;
	esac
else
	local previous="${COMP_WORDS[$(($COMP_CWORD - 1))]}"

	trace '$previous'

	case "$previous" in
	-d|--dest)
		COMPREPLY+=($(compgen -o nospace -d -- "$current"))
		trace '${COMPREPLY[@]}'
		return
		;;
	*)
		opts="${opts[list]} ${opts[install]} ${opts[install-remove]} ${opts[remove]} ${COMMANDS[@]} ${LONG_OPTS[@]/#/--} ${SHORT_OPTS[@]/#/-}"
		;;
	esac



fi

#	echo command="$command" >&2
#	echo at="$at" >&2
#	echo COMP_CWORD="$COMP_CWORD" >&2
#	echo opts="$opts" >&2

	COMPREPLY+=($(compgen -W "$opts" -- "$current"))
}

_org() {
    local cur prev words cword split

    _init_completion -s || return

    #echo "Cur: $cur" # Contains the partial word
    #echo "Prev: $prev" # The previous word (the command if no previous one)
    #echo "Words: $words" # Array of all words? (like $@ ?)
    #echo "CWord: $cword" # Number for current word (first word = 1, ...)
    #echo "Split: $split" # ???

    # Since ALL words in $COMPREPLY get suggested (regardless whether
    # the user partially typed one) compgen handles only returning
    # the relevant ones

    if [ $cword -eq 1 ]; then
        OPKG_COMMANDS=("update" "upgrade" "install" "configure" "remove" "flag")
        OPKG_COMMANDS+=("list" "list-installed" "list-upgradable" "list-changed-conffiles")
        OPKG_COMMANDS+=("files" "search" "find" "info" "status" "download" "compare-versions")
        OPKG_COMMANDS+=("print-architecture" "depends" "whatdepends" "whatdependsrec")
        OPKG_COMMANDS+=("whatrecommends" "whatsuggests" "whatprovides" "whatconflicts")
        OPKG_COMMANDS+=("whatreplaces")
        COMPREPLY=($(compgen -W '${OPKG_COMMANDS[@]}' -- "$cur"))
    else
	    COMPREPLY=()
    	OPKG_COMMANDS_WITH_PKG_COMPLETE=("install" "remove") # Todo: more

    	if [ $cword -gt 1 ] && [[ " ${OPKG_COMMANDS_WITH_PKG_COMPLETE[@]} " =~ " ${words[1]} " ]]; then
        	COMPREPLY+=($(compgen -W "$(packages)" -- "$cur"))
    	fi

    	OPKG_COMMANDS_WITH_FILE_COMPLETE=("install") # Todo: more
    	if [ $cword -gt 1 ] && [[ " ${OPKG_COMMANDS_WITH_FILE_COMPLETE[@]} " =~ " ${words[1]} " ]]; then
	        # Pretty primitive and does subdirectories not properly
        	COMPREPLY+=($(compgen -W '$(ls)' -- "$cur"))
    	fi
	fi
}

complete -F _opkg opkg

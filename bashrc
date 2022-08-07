#!/bin/bash
[ -z "$PS1" ] && return

set -o vi


if [ "$PREFIX" = "/data/data/com.termux/files/usr" ]; then
	export HOSTNAME="chromebook"
	export USER="termux"
	export OS_TERMUX=1
fi

[ -f ~/.localrc ] && source ~/.localrc

function .branch() {
	#git branch 2> /dev/null | sed -e '/^[^*]/d' -e  's/.* \(.*\)/ [\1'$(.change)']/'
	git branch -v 2> /dev/null | sed \
		-e '/^[^*]/d' \
		-e 's/^..(*\([^ ]*\)[^\[]*/\1/' \
		-e 's/\].*$//' \
		-e 's/\[\|$/'$(.change)' /' \
		-e 's/ahead /+/' \
		-e 's/behind /-/' \
		-e 's/\( .*\)$/\1/' \
		-e 's/^/ [/' \
		-e 's/ *$/]/'
}

function .change() {
	git diff-index HEAD 2> /dev/null | sed 's/.\+$/*/' | uniq
}

function .path() {
	groot=$(git rev-parse --show-toplevel 2>/dev/null || echo '@@@')

	case $PWD in
		$HOME) echo "~/";;
		$HOME/${PWD##*/}) echo "~/${PWD##*/}";;
		$groot*) echo "git:${groot##*/}${PWD##$groot}/";;
		"/") echo "/";;
		*) echo "../${PWD##*/}/";;
	esac
}

export PATH="~/bin/:$PATH"
export PS1="\n\e[33;1m<$HOSTNAME>\e[91m\$(.branch)\n\e[34m@$USER \e[32m\$(.path) \e[90m\\$\e[0m "
export EDITOR="$(which vim) -p"

function dotfiles() {
	DOTREPO=$(dirname $(readlink ~/.bashrc))

	case "$1" in
		repo)
			cd $DOTREPO
			;;
		list|install|uninstall|status|sync)
			if [ -z "$2" ]; then 
				make -sC $DOTREPO $1
			else
				make -sC $DOTREPO $1 FILE="$2"
			fi

			if [ "$1" = "sync" ]; then
				source ~/.bashrc
			fi
			;;
		track|untrack|link|unlink|edit)
			if [ -z "$2" ]; then 
				dotfiles

				return
			fi

			make -sC $DOTREPO $1 FILE="$2"

			case $2 in
				bashrc|localrc)
					echo "RELOADING ~./.$2"
					source ~/.bashrc
					;;
			esac
			;;
		*)
			echo -e "FRINKnet Dotfile Management System v1.13.02\n© 2020 Frink & Friends - Licenced: BSD Zero

  Usage:

	dotfiles [ACTION] [FILE]

  Actions:

	install
	unistall

	link [FILE]
	unlink [FILE]
	track [FILE]
	untrack [FILE]
	edit [FILE]

	repo
	list
	status
	sync"
			;;
	esac
}

dotfiles status

function note() {
	[ -z "$1" ] && echo -e "

  Usage:

	note [LIST] [NOTE]

	" && return


	[ ! -d ~/.notes ] && mkdir ~/.notes

	if [ -z "$2" ]; then
		[ -f ~/.notes/$1 ] && cat ~/.notes/$1 | sort
	elif [ "$2" = "edit" ]; then
		$EDITOR ~/.notes/$1
	elif [ "$2" = "clear" ]; then
		rm -rf ~/.notes/$1
	else
		echo ${@:2} >> ~/.notes/$1
	fi
}

alias todo="note todo"

alias open="xdg-open"
alias o="open"
alias ls="ls --color=auto"
alias ll="ls -hang"

function ff() {
	find . -ipath "*$1*"
}

function cdx() {
	if [ -z "$2" ]; then
		cd "$1"
	else
		cdx "$1/$2" ${@:3}
	fi
}

function cdrun() {
	cd $1
	${@:2}
	cd -
}

function mkcd() {
	if [ -z "$2" ]; then
		mkdir -p "$1"
		cd "$1"
	else
		mkcd "$1/$2"
		${@:3}
	fi
}

alias ..="cdx .."
alias ~="cdx ~"

if [ -d ~/Work ]; then
	alias wk="mkcd ~/Work"
fi

alias rgrep="grep -r"
alias lgrep="grep -rl"
alias pgrep="ps -a | grep"

function hgrep() {
	history | grep -i "$(echo $@)"
}

function vgrep() {
	$EDITOR $(lgrep $@)
}

function g.() {
	cdx "$(git rev-parse --show-toplevel 2>/dev/null || echo '.')" $@

	unalias $(alias|grep "alias g\."|cut -d"=" -f1|cut -d" " -f2) &> /dev/null

	for x in $(ls -d */ 2>/dev/null); do
		alias g.${x%/}="cdx $PWD/$x";
		echo g.${x%/}
	done
}

function v.() {
	unalias $(alias|grep "alias v\."|cut -d"=" -f1|cut -d" " -f2) &> /dev/null


	for x in $(ls -d */ 2>/dev/null); do
		alias v.${x%/}="unset VFILES;cdrun '$PWD/$x' v";
		echo v.${x%/}
	done
}

function -() {
	cd -
}

alias rm.="rm -rf"

# vim stuff
alias vd="vimdiff"

function v() {
	if [ -n "$1" ]; then
		export VFILES=$(
			for x in "$@"; do
				for x in $(find . -ipath "*$x*"); do
					echo $PWD${x/.};
				done
			done
		)
	fi

	if [ -n "$VFILES" ]; then
		$EDITOR $VFILES
	else
		$EDITOR $PWD
	fi
}

alias vrc="dotfiles edit bashrc"
alias vvc="dotfiles edit vimrc"
alias vrc.="[ ! -f ~/.localrc ] && touch ~/.localrc && ln -s ~/.localrc $DOTREPO/localrc;dotfiles edit localrc"

alias fio="rash https://raw.githubusercontent.com/boazsegev/facil.io/master/scripts/new/app"

function surash() {
	wbody $1 |sudo bash ${@:2}
}

function rash() {
	bash <(wbody $1) ${@:2}
}

if [ ! $OS_TERMUX ]; then
	alias apt="sudo apt"
fi

alias drun="docker exec -it"

function on() {
	(
		exe=( ${@:2} )
		dtach -A /dev/shm/on-$1 ${exe[@]:-bash}
	)
}

function whos() {
	local tld=${1#*.}
	local dns=$(whois -h whois.iana.org $tld|grep whois:|sed 's/whois:\s\+//')

	if [ -z "$dns" ]; then
		echo "No Whois Sever found for .$tld!"
		return
	else
		echo "Server: $dns"
	fi

	whois -h $dns $@
}

function dns() {
	dig +nocmd hinfo +multiline +noall +answer $1
	dig +nocmd ns +multiline +noall +answer $1
	dig +nocmd soa +multiline +noall +answer $1
	dig +nocmd srv +multiline +noall +answer $1
	dig +nocmd mx +multiline +noall +answer $1
	dig +nocmd cname +multiline +noall +answer $1
	dig +nocmd a +multiline +noall +answer $1
	dig +nocmd txt +multiline +noall +answer $1
}

function error() {
	echo $@ >&2;
}

alias wcat="wget -O- --method=GET"
alias wbody="wget -qO- --method=GET"
alias whead="wget -qS --method=HEAD"
alias wpost="wget -qO- --body-file=- --method=POST"
alias wput="wget -qO- --body-file=- --method=PUT"

function api() {
	if [ -z "$2" ]; then
		echo "
API command line accessor via wget.

Usage: api [options] [method] [path] [selection]

	--set: set url endpoint and wget arguments
	--call: show the actual wget call
	--test: test the call you are making
	--debug: debug wget call
		"
		return
	fi

	if [ ! -t 0 ] && [ -z "$API_BODY" ] && [ "${1^^}" != "--PARSE" ]; then
		export API_BODY="$(mktemp -p /dev/shm/)"
		umask 077
		cat - > $API_BODY
	fi

	case "${1^^}" in
		--SET)
			export API_URL="${2%\?*}"
			export API_QUERY="${2#*\?}"
			export API_ARGS=( "${@:3}" )
			;;
		--CALL)
			echo $(
				API_URI="${API_URL%/}$([ -n "$3" ] && echo /)$(echo ${3#/} | cut -d? -f1)"
				API_URI+="?$([ -n "$API_QUERY" ] && echo "$API_QUERY&")$(echo ${3#/}? | cut -d? -f2)"

				echo wget -O- --content-on-error=on

				[[ "${2^^}" =~ POST|PUT ]] && [ -n "$API_BODY" ] && echo --body-file=$API_BODY

				echo --method="${2^^}"

				for x in "${API_ARGS[@]}"; do
					echo "${x%%=*}$([ "${x%%=*}" != "${x#*=}" ] && echo  ="'${x#*=}'") "
				done

				echo  "'$API_URI'"
			)
			;;
		--DEBUG)
			(
				export API_ARGS=( -vd --save-headers "${API_ARGS[@]}" )

				api --call "${@:2:2}" | bash | less
			)
			api --call "${@:2:2}"
			;;
		--TEST)
			(
				export API_URL="https://httpbin.org/anything"

				api "${@:2}" 
			)
			;;
		GET|POST|PUT|DELETE|HEAD|OPTIONS)
			(
				export API_ARGS=( -q "${API_ARGS[@]}" )

				api --call "${@:1:2}" | bash
			) | (
				API_RTN=$( cat )

				echo "$API_RTN" | jq "${@:3}" 2>/dev/null || echo "$API_RTN"
			)

			;;
		*)
			api
			;;
	esac

	if [[ "${1^^}" =~ POST|PUT ]]; then
		rm -f $API_BODY;
		unset API_BODY;
	fi
}

if [ -n "$(which quasar)" ]; then
	alias qdev="(on quasar quasar dev)"
	alias qbuild="(on quasar quasar build)"
fi

function uml() {
	uml=${1%.*}
	vim $uml.uml
	plantuml -progress $uml.uml
	wl-copy < $uml.png
}

alias clip="wl-copy <"
alias copy="wl-copy"
alias paste="wl-paste"

alias rm.orig="find . -type f -iname "*.orig" -exec rm {} \;"
alias rm.swp="find . -type f -iname "*.swp" -exec rm {} \;"

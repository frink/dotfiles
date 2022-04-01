# interactive shells only
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

	case $1 in
		repo)
			cd $DOTREPO
			;;
		list|install|uninstall|status|resync)
			if [ -z "$2" ]; then 
				make -sC $DOTREPO $1
			else
				make -sC $DOTREPO $1 FILE="$2"
			fi

			if [ "$1" = "resync" ]; then
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
	resync"
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

function cdr() {
	(cd $1 && ${@:2})
}

alias ..="cdx .."
alias ~="cdx ~"

if [ -d ~/Work ]; then
	alias wk="cdx ~/Work"
fi

alias rgrep="grep -r"
alias lgrep="grep -rl"
alias pgrep="ps -a | grep"

function hgrep() {
	history | grep "$(echo $@)"
}

function vgrep() {
	$EDITOR $(lgrep $@)
}

function g.() {
	cdx "$(git rev-parse --show-toplevel 2>/dev/null || echo '.')" $@

	unalias $(alias|grep "alias g\."|cut -d"=" -f1|cut -d" " -f2)

	for x in $(ls -d */ 2>/dev/null); do
		alias g.${x%/}="cdx $PWD/$x";
		echo g.${x%/}
	done
}

function v.() {
	unalias $(alias|grep "alias v\."|cut -d"=" -f1|cut -d" " -f2)

	for x in $(ls -d */ 2>/dev/null); do
		alias v.${x%/}="cdr '$PWD/$x' v";
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
	if [ -n "$@" ]; then
		export VFILES=( "$@" )
	fi

	echo "$VFILES"

	[ -n "" ] && if [ -n "$VFILES" ]; then
		$EDITOR $(
			for x in "$VFILES"; do
				find . -ipath "*$x*"
			done
		)
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
	dtach -A /dev/shm/on-$1 ${@:2}
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

alias wcat="wget -O- --method=GET"
alias wbody="wget -qO- --method=GET"
alias whead="wget -qS --method=HEAD"
alias wpost="wget -qO- --body-file=- --method=POST"
alias wput="wget -qO- --body-file=- --method=PUT"

function api() {
	umask 077

	if [ ! -t 0 ]; then
		[ -z "$API_BODY" ] && export API_BODY="$(mktemp -p /dev/shm/)";
		cat - > $API_BODY;
	fi

	case "${1^^}" in
		--SET) export API_URL="$2"; export API_ARGS=( "${@:3}" );;
		--CALL) echo wget -dvO- $([[ ${2^^} =~ PUT|POST ]] && echo --body-file=$API_BODY) --method="${2^^:-GET}" $(for x in "${API_ARGS[@]}"; do echo "${x%%=*}$([ -n "${x#*=}" ] && echo  ="'${x#*=}'") "; done)"${API_URL%/}$([ -n "$3" ] && echo /)${3#/}";;
		--DEBUG) wget -dvO- --save-headers $([[ ${2^^} =~ PUT|POST ]] && echo --body-file=$API_BODY) --method="${2^^:-GET}" "${API_ARGS[@]}" "${API_URL%/}$([ -n "$3" ] && echo /)${3#/}" 2>&1 | less; api --call "${@:2}";;
		GET|PUT|POST|DELETE|HEAD) wget -qO- --content-on-error $([[ ${1^^} =~ PUT|POST ]] && echo --body-file=$API_BODY) --method="${1^^}" "${API_ARGS[@]}" "${API_URL%/}$([ -n "$2" ] && echo /)${2#/}";;
		*) echo "
API command line accessor via wget.

Usage: api [options] [method] [path]

	--set: set url endpoint and wget arguments
	--call: show the actual wget call
	--debug: debug wget call
		";;
	esac

	if [[ "${1^^}" =~ "GET|PUT|POST|DELETE|HEAD" ]]; then
		rm -f $API_BODY
		unset $API_BODY
	fi
}

if [ -n "$(which quasar)" ]; then
	alias qdev="on quasar quasar dev"
	alias qbuild="on quasar quasar build"
fi

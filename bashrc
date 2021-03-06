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
export EDITOR=$(which vim)

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

	" && exit


	[ ! -d ~/.notes ] && mkdir ~/.notes

	if [ -z "$2" ]; then
		[ -f ~/.notes/$1 ] && cat ~/.notes/$1 | sort
	elif [ "$2" = "edit" ]; then
		$EDITOR ~/.notes/$1
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

alias rgrep="grep -r"
alias lgrep="grep -rl"
alias hgrep="history | grep"
alias pgrep="ps -a | grep"

function vgrep() {
	vim -p $(lgrep $@)
}

alias ..="cdx .."
alias ~="cdx ~"

function ..g() {
	groot=$(git rev-parse --show-toplevel 2>/dev/null || echo '..')

	cdx "$groot" $@
}

function -() {
	cd -
}

alias rm.="rm -rf"

# vim stuff
alias vd="vimdiff"

function v() {
	$EDITOR $(find . -ipath "*$1*")
}

alias vrc="dotfiles edit bashrc"
alias vvc="dotfiles edit vimrc"
alias vrc.="[ ! -f ~/.localrc ] && touch ~/.localrc && ln -s ~/.localrc $DOTREPO/localrc;dotfiles edit localrc"

alias fio="rash https://raw.githubusercontent.com/boazsegev/facil.io/master/scripts/new/app"

function rash() {
	bash <(curl -s $1) ${@:2}
}

if [ ! $OS_TERMUX ]; then
	alias apt="sudo apt"
fi

alias drun="docker exec -it"

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

alias wcat="wget -O- --method=GET"
alias wbody="wget -qO- --method=GET"
alias whead="wget -qS --method=HEAD"
alias wpost="wget -qO- --body-file=- --method=POST"
alias wput="wget -qO- --body-file=- --method=PUT"

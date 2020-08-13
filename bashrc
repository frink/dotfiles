set -o vi

source ~/.localrc

function .branch() {
	git branch 2> /dev/null | sed '/^[^*]/d' | sed 's/.* \(.*\)/ [\1'$(.change)']/'
}

function .change() {
	git diff-index HEAD 2> /dev/null | sed 's/.\+$/*/'
}

function .path() {
	echo
}

export PATH="~/bin/:$PATH"
export PS1="\n\e[33m<$HOSTNAME>\e[31m\$(.branch)\n\e[34m@$USER \e[32m../\W/ \e[34m\\$\e[0m "
export EDITOR=$(which vim)

function dotfiles() {
	DOTREPO=$(dirname $(readlink ~/.bashrc))

	case $1 in
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
					source ~/.$2
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

	track [FILE]
	untrack [FILE]

	link
	unlink

	edit
	repo

	list
	sync
	status

			"
			;;
	esac
}

alias ls="ls --color=auto"
alias ll="ls -hang"

function ff() {
	find . -iname "*$1*"
}

function cdx() {
	if [ -z "$2" ]; then
		cd "$1"
	else
		cdx "$1/$2" ${@:3}
	fi
}

alias rgrep="grep -r"
alias hgrep="history | grep"
alias pgrep="ps -a | grep"

alias ..="cdx .."
alias ~="cdx ~"

function -() {
	cd -
}

alias rm.="rm -rf"

# vim stuff
alias vd="vimdiff"

function v() {
	$EDITOR $(find . -iname "*$1*")
}

alias vrc="dotfiles edit bashrc"
alias vrc.="dotfiles edit localrc"

alias fio="rash https://raw.githubusercontent.com/boazsegev/facil.io/master/scripts/new/app"

function rash() {
	bash <(curl -s $1) ${@:2}
}

alias apt="sudo apt"
alias drun="docker exec -it"

alias wcat="wget -O- --method=GET"
alias wbody="wget -qO- --method=GET"
alias whead="wget -qS --method=HEAD"
alias wpost="wget -qO- --body-file=- --method=POST"
alias wput="wget -qO- --body-file=- --method=PUT"

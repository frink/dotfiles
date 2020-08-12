set -o vi

export PATH="~/bin/:$PATH"
export PS1="\n\e[33m<\h>\n\e[32m../\W/ \e[34m\\$\e[0m "
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

			if [ "$2" == "bashrc" ]; then
				echo "RELOADING ~./bashrc"
				source ~/.bashrc
			fi
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

	list
	sync
	status

			"
			;;
	esac
}

function rash() {
	bash <(curl -s $1) ${@:2}
}

function ff() {
	find . -iname "*$1*"
}

function v() {
	$EDITOR $(find . -iname "*$1*")
}

function cdx() {
	if [ -z "$2" ]; then
		cd "$1"
	else
		cdx "$1/$2" ${@:3}
	fi
}

function -() {
	cd -
}

function wcat() {
	wcat -O- 
}



alias apt="sudo apt"
alias drun="docker exec -it"
alias vrc="dotfiles edit bashrc"
alias vd="vimdiff"
alias fio="rash https://raw.githubusercontent.com/boazsegev/facil.io/master/scripts/new/app"
alias ll="ls -hang"
alias rf="rm -rf"
alias rgrep="grep -r"
alias hgrep="history | grep"
alias pgrep="ps -a | grep"
alias ..="cdx .."
alias ~="cdx ~"
alias - ="cd -"

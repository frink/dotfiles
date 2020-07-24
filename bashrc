set -o vi

export PATH="~/bin/:$PATH"
export PS1="\n\e[33m<\h>\n\e[32m../\W/ \e[34m\\$\e[0m "
export EDITOR=$(which vim)

function dotfiles() {
	case $1 in
		install|uninstall|update|list)
			make -sC $(dirname $(readlink ~/.bashrc)) $1

			if [ "$1" = "update" ]; then
				source ~/.bashrc
			fi
			;;
		track|untrack|link|unlink|edit)
			if [ -z "$2" ]; then 
				dotfile

				return
			fi

			make -sC $(dirname $(readlink ~/.bashrc)) $1 FILE="$2"

			if [ "$2" == "bashrc" ]; then
				echo "RELOADING ~./bashrc"
				source ~/.bashrc
			fi
			;;
		*)
			echo "FRINKnet Dotfile Management System v1.13.2
© 2020 Frink & Friends - Licence: BSD Zero

	Usage:
		dotfiles [ACTION] [FILE]

	Actions:
		install
		unistall
		track
		untrack
		link
		unlink
		edit
		list
		update

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

alias vrc="dotfiles edit bashrc"
alias fio="rash https://raw.githubusercontent.com/boazsegev/facil.io/master/scripts/new/app"
alias ll="ls -hang"
alias rf="rm -rf"
alias rgrep="grep -r"
alias hgrep="history | grep"


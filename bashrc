set -o vi

export PS1="\n\e[32m\W \e[34m\\$\e[0m "

function dotfiles() {
	case $1 in
		install|uninstall)
			make -sC $(dirname $(readlink ~/.bashrc)) $1 FILE="$2"
			;;
		track|untrack|link|unlink|edit)
			if [ -n "$2" ]; then 
				make -sC $(dirname $(readlink ~/.bashrc)) $1 FILE="$2"
			else
				dotfile
			fi
			;;
		*)
			echo "
	Usage:
		dotfile [action] [file]

	Actions:
		install
		unistall
		track
		untrack
		link
		unlink
		edit

			"
			;;
	esac
}

function rash() {
	bash <(curl -s $1) ${@:2}
}


alias vrc="vim ~/.bashrc; source ~/.bashrc"
alias fio="rash https://raw.githubusercontent.com/boazsegev/facil.io/master/scripts/new/app"
alias ll="ls -hang"
alias rf="rm -rf"
alias rgrep="grep -r"


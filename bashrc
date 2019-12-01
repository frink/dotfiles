set -o vi

export PS1="\n\e[32m\W \e[34m\\$\e[0m "

function rash() {
	bash <(curl -s $1) ${@:2}
}

alias vrc="vim ~/.bashrc; source ~/.bashrc"
alias fio="rash https://raw.githubusercontent.com/boazsegev/facil.io/master/scripts/new/app"
alias ll="ls -hang"
alias rf="rm -rf"
alias rgrep="grep -r"


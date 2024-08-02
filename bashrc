#!/bin/bash
[ -z "$PS1" ] && return

set -o vi

if [ "$PREFIX" = "/data/data/com.termux/files/usr" ]; then
  export HOSTNAME="chromebook"
  export USER="termux"
  export OS_TERMUX=1
fi

function .branch() {
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
  git diff-inde HEAD 2> /dev/null | sed 's/.\+$/*/' | uniq
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

type -p wslview > /dev/null && export BROWSER="wslview"
type -p see > /dev/null || alias see="$BROWSER"

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
    [ -f ~/.notes/$1 ] && cat ~/.notes/$1
  elif [ "$2" = "sort" ]; then
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
alias idea="note ideas"

alias open="xdg-open"
alias o="open"
alias ls="ls --color=auto --file-type --group-directories-first --literal"
alias ll="ls -hang"
alias path="echo $PATH | tr : '\n'"

function ff() {
  find . -ipath "*$1*"
}

function cdrun() {
  cd $1
  ${@:2}
  cd -
}

function x() {
    [ -n "$COMP_CWORD" ] && set "${COMP_WORDS[@]:1:$COMP_CWORD}"

    COMPREPLY=( $(compgen -W ".. $(
      $(
        IFS=/;
        set "${1/#~/$HOME}" "${@:2}"
        echo "$*" | \
        sed -E 's|^(/)?(.*/)?(.*)$|ls -d \1./\2/\3*/|; s|\.\.\*/$|..|'
      ) | sed 's|^\(.*/\)\?\([^/]\+\)/\?|\2|'
    )"  -- "${@:$#}") )

    [ -z "$COMP_CWORD" ] && echo "${COMPREPLY[@]}"
}

function cdx() {
  local ifs="$IFS"
  IFS='/'
  cd "$*"
  IFS="$ifs"
}

function mkcd() {
  local ifs="$IFS"
  IFS='/'
  mkdir -p "$*"
  cd "$*"
  IFS="$ifs"
}

mkx ()
{
    eval 'function '$1'(){
        [ -z "$COMP_CWORD" ] && '$2' "'$3'" "${@}" && return


        echo "before ${COMP_WORDS[@]}"

        ((COMP_CWORD++))
        COMP_WORDS=( "'$3'" "${COMP_WORDS[@]}" )

        echo "modified ${COMP_WORDS[@]}"

        x
    }'
    complete -F "$1" "$1"
}

complete -F x x
complete -F x cdx
complete -F x mkcd

mkx xx x ./
mkx wk mkcd ~/Work/
mkx .. cdx ../
mkx ~ cdx ~/

alias rgrep="grep -r"
alias lgrep="grep -lr"
alias pgrep="ps -a | grep"

function hgrep() {
  history | grep -i "$(echo $@)"
}

function vgrep() {
  $EDITOR $(lgrep "$@")
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

alias rmf="rm -rf"

# vim stuff
alias vd="vimdiff"
alias vim="vim -p"
alias svim="sudo vim -p"

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

if [ ! $OS_TERMUX ]; then
  alias apt="sudo apt"
  alias svc="sudo systemctl"
fi

function install-docker() {
  local ARCH=$(dpkg --print-architecture)
  local DISTRO=$(. /etc/os-release && echo "$ID")
  local VERSION=$(. /etc/os-release && echo "$VERSION_CODENAME")

  # Add Docker's official GPG key:
  sudo apt-get update
  sudo apt-get install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/$DISTRO/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  echo \
    "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$DISTRO \
    $VERSION stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  sudo usermod -aG docker $(whoami)
}

# alias if docker not setup
type -p docker > /dev/null || alias docker="install-docker && unalias docker && docker"

function docker-clean() {
  # Stop all containers
  docker stop $(docker ps -qa)

  # Remove all containers
  docker rm -f $(docker ps -qa)

  # Remove all images
  docker rmi -f $(docker images -qa)

  # Remove all volumes
  docker volume rm -f $(docker volume ls -q)

  # Remove all networks
  docker network rm -f $(docker network ls -q)
}

#docker tester
function dtest() {
  [ ! -f Dockerfile ] && echo "No Dockerfile." && return

  docker build . -t tester

  opt=()
  cmd=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --) shift; cmd=("$@"); break ;;
      *) opt+=("$1"); shift ;;
    esac
  done

  docker run -it "${opt[@]}" tester "${cmd[@]}"
}

alias drun="docker exec -it"
alias dps="docker ps -a -q"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dca="dcd&&dcu"

# alias if nhost not setup
type -p nhost > /dev/null || alias nhost="rash https://raw.githubusercontent.com/nhost/cli/main/get.sh && unalias nhost && nhost"

function install-psql() {
  local VERSION=$(. /etc/os-release && echo "$VERSION_CODENAME")

  # Add Docker's official GPG key:
  sudo apt-get update
  sudo apt-get install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc -o /etc/apt/keyrings/postgres.asc
  sudo chmod a+r /etc/apt/keyrings/postgres.asc

  # Add the repository to Apt sources:
  echo \
    "deb [signed-by=/etc/apt/keyrings/postgres.asc] https://apt.postgresql.org/pub/repos/apt \
    $VERSION-pgdg main" | \
    sudo tee /etc/apt/sources.list.d/postgres.list > /dev/null

  sudo apt-get update -y
  sudo apt-get install -y postgresql-client
}

type -p psql > /dev/null || alias psql="install-psql && unalias psql && psql"

function sql.run() {
  if [ -z "$2" ]; then
    if [ ! -t 0 ]; then
      cat - | psql $1
    else
      psql $1
    fi
  elif [ "${2^^}" == "DUMP" ]; then
    pg_dump "$1" "${@:3}"
  else
    echo "${@:2};" | psql "$1"
  fi
}

function sql.add() {
  alias sql.${1}="sql.run '${2}'"
}

function sql.del() {
  unalias sql.${1}
}

function sqit() {
  [ ! -f "sqitch.plan" ] && echo "not a sqitch folder" && return

  case ${1^^} in
    ADD)
      git reset
      git status
      sqitch add "$2" -n "Adding $2"
      $EDITOR "deploy/$2.sql" "verify/$2.sql" "revert/$2.sql" sqitch.plan
      git add "deploy/$2.sql" "verify/$2.sql" "revert/$2.sql" sqitch.plan
      git commit -m "Adding $2"
      ;;
    FIX)
      git reset
      git status
      sqitch rework "$2" -n "Fixing $2"
      $EDITOR "deploy/$2.sql" "verify/$2.sql" "revert/$2.sql" sqitch.plan
      git add "deploy/$2.sql" "verify/$2.sql" "revert/$2.sql" sqitch.plan
      git commit -m "Fixing $2"
      ;;
    TAG)
      sqitch tag "$2" -n "Tagging $2"
      get tag "$2" -m "Tagging $2"
      ;;
    MV)
      [ ! -f "deploy/$2.sql" ] && echo "deploy/$2.sql does not exist" && return
      [ ! -f "verify/$2.sql" ] && echo "verify/$2.sql does not exist" && return
      [ ! -f "revert/$2.sql" ] && echo "revert/$2.sql does not exist" && return
      [ -f "deploy/$3.sql" ] && echo "deploy/$3.sql already exist" && return
      [ -f "verify/$3.sql" ] && echo "verify/$3.sql already exist" && return
      [ -f "revert/$3.sql" ] && echo "revert/$3.sql already exist" && return
      
      git mv "deploy/$2.sql" "deploy/$3.sql"
      git mv "verify/$2.sql" "verify/$3.sql"
      git mv "revert/$2.sql" "revert/$3.sql"

      $EDITOR "deploy/$3.sql" "verify/$3.sql" "revert/$3.sql" sqitch.plan
      git commit -m "Moving $2 $3"
      ;;
    *)
      echo -e "Simple Quick Integration Transfer v1.0.02\n©2020 Frink & Friends - Licenced: BSD Zero

  Usage:

  sqit [ACTION] [name]

  Actions:

  add [name]
  fix [name]
  tag [name]
  "
      ;;
  esac
}

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

alias wcat="wget -qSO- --method=GET"
alias wbody="wget -qO- --method=GET"
alias whead="wget -qS --method=HEAD"
alias wpost="wget -qO- --body-file=- --method=POST"
alias wput="wget -qO- --body-file=- --method=PUT"

function surash() {
  wbody $1 | sudo bash ${@:2}
}

function rash() {
  wbody $1 | bash ${@:2}
}

function wtgz() {
  wbody $1 | tar xz ${@:2}
}

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
alias rm~="find . -type f -iname "*~" -exec rm {} \;"

function lines() {
  sed -n "${1//-/,}p" "$2"
}

function words() {
  cat $1 | tr 'A-Z' 'a-z' | \
  egrep -o "\b[[:alpha:]]+\b" | \
  awk '{ count[$0]++ }
  END{
  for(ind in count)
  { printf("%-14s%d\n",ind,count[ind]); }
  }' | sort -k2 -n -r
}

function fringpong() {
  echo "A server will respond 12 times on port 1234"

  sudo apt install netcat -y

  (
    local I="0"

    while [ $I -lt 12 ];do
      I=$[$I+1]
      echo -e "HTTP/1.1 200\r\nContent-Type:text/html\r\n\r\nFRINGPONG $I" | nc -lvN 1234 2>1
    done >/dev/null &
  )
}

completer() {
    local command=( "$@" )
    local cmd_name="${command[0]}"
    local func_name=$(complete -p "$cmd_name" 2>/dev/null | awk '{print $3}')

    if [[ -z "$func_name" ]]; then
        echo "No completion function found for command: $cmd_name"
        return
    fi

    # Ensure COMP_WORDS includes a placeholder for the current word being completed
    COMP_WORDS=("${command[@]}" "")
    COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))

    # Set other completion environment variables
    COMP_LINE="${command[*]}"
    COMP_POINT=${#COMP_LINE}

    # Clear COMPREPLY before invoking the completion function
    COMPREPLY=()

    echo COMP_WORDS=\( ${COMP_WORDS[@]} \) COMP_CWORD=$COMP_CWORD COMP_LINE=\"$COMP_LINE\" COMP_POINT=$COMP_POINT $func_name\;echo \${COMPREPLY[@]}

    # Call the completion function
    "$func_name"

    # Output and sort the completions
    for completion in "${COMPREPLY[@]}"; do
        echo "$completion"
    done | sort

    # Clear COMP_WORDS and COMPREPLY to prevent side effects
    unset COMP_WORDS
    unset COMPREPLY
    unset COMP_CWORD
    unset COMP_LINE
    unset COMP_POINT
}

[ -f ~/.localrc ] && source ~/.localrc

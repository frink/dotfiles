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

export PATH="~/.local/bin/:/usr/local/go/bin/:$PATH"
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

  note [LIST]
  note [LIST] [COMMAND]
  note [LIST] [NOTE]

  Commands:

  edit - Edit in ${EDITOR}
  clear - Clear everything in the list
  sort - Sort the list A-Z
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

function list() {
  local name cmd file

  name="$1"
  shift
  cmd="$1"
  shift

  # If missing arguments, show help
  if [[ -z "$name" || -z "$cmd" ]]; then
    cmd="help"
  fi

  mkdir -p "$HOME/.lists"
  file="$HOME/.lists/$name.csv"

  # Only allow 'alias', 'help', and 'define' if the file does not exist
  if [[ ! -f "$file" && "$cmd" != "alias" && "$cmd" != "help" && "$cmd" != "define" ]]; then
    echo "List '$name' does not exist. Use 'define' to create it."

    return 1
  fi

  case "$cmd" in
    edit)
      $EDITOR "$file"
      ;;

    alias)
      eval "
      ${name}() {
        if [[ \"\$1\" == \"edit\" ]]; then
          list $name \"\$@\"
        else
          list $name \"\$@\" 2>&1 | sed  -e 's/^  Usage: list name/  Usage: $name/' -e '/^    alias .*/d'
        fi
      }
      "
      ;;

    define)
      local old_header new_header old_fields new_fields out
      local -a field_map lost

      new_header="$*"

      if [[ -z "$new_header" ]]; then
        echo "Please provide fields in your definition..."
        return 1
      fi

      if [[ ! -f "$file" ]]; then
        echo "$new_header" > "$file"
      else
        old_header=$(head -n1 "$file")

        IFS=',' read -r -a old_fields <<< "${old_header//↓/}"
        IFS=',' read -r -a new_fields <<< "$new_header"

        # Find lost columns
        for old in "${old_fields[@]}"; do
          found=0

          for new in "${new_fields[@]}"; do
            [[ "$old" == "$new" ]] && found=1 && break
          done

          [[ $found -eq 0 ]] && lost+=("$old")
        done

        if (( ${#lost[@]} > 0 )); then
          echo "Warning these fields will be deleted: ${lost[*]}"

          read -p "Are you okay with data loss? [y/N]: " confirm

          [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; return 1; }
        fi

        for i in "${!new_fields[@]}"; do
          field_map[$i]=-1

          for j in "${!old_fields[@]}"; do
            if [[ "${new_fields[i]}" == "${old_fields[j]}" ]]; then
              field_map[$i]=$j

              break
            fi
          done
        done

        echo "$new_header" > "$file.tmp"

        tail -n +2 "$file" | while IFS=',' read -r -a row; do
          out=()

          for i in "${!new_fields[@]}"; do
            if [[ ${field_map[$i]} -ge 0 ]]; then
              out+=("${row[${field_map[$i]}]}")
            else
              out+=("")
            fi
          done

          (IFS=','; echo "${out[*]}")
        done >> "$file.tmp"

        mv "$file.tmp" "$file"
      fi
      ;;

    add)
      local input key

      input="$*"
      key="${input%%,*}"
    
      if grep -q "^${key}\(,\|$\)" "$file"; then
        read -p "Entry with key '$key' exists. Replace it? [y/N] " -n 1 -r
        echo

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          echo "Add cancelled."
          return 1
        fi

        sed -i.bak "/^${key//\//\\/}\(,\|$\)/d" "$file"
        rm -f "$file.bak"
      fi
    
      echo "$input" >> "$file"

      list "$name" sort
      ;;

    update)
      local key field value arg updates_str

      key="$1"
      shift
      updates_str=""

      # Build updates string: field1=value1,field2=value2,...
      for arg in "$@"; do
        field="${arg%%=*}"
        value="${arg#*=}"
        updates_str+="${field}=${value},"
      done
      updates_str="${updates_str%,}"  # Remove trailing comma

      awk -v key="$key" -v updates="$updates_str" '
        BEGIN {
          FS=OFS=","
          # Parse updates into an array
          n = split(updates, arr, ",")
          for (i = 1; i <= n; i++) {
            split(arr[i], kv, "=")
            upd[kv[1]] = kv[2]
          }
        }
        NR==1 {
          for (i=1; i<=NF; i++) {
            # Remove down arrow (↓) from header
            header[i] = gensub(/↓/, "", "g", $i)
          }
          print $0
          next
        }
        $1 == key {
          for (i=2; i<=NF; i++) {
            if (header[i] in upd) $i=upd[header[i]]
          }
        }
        { print $0 }
      ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

      field=$(head -n1 "$file" | cut -d',' -f1)

      list "$name" sort > /dev/null
      list "$name" filter "$field=\"$key\""
      ;;


    remove)
      {
        head -n1 "$file"
        tail -n +2 "$file" | grep -F -- "$*"
      } | column -t -s,

      echo    # move to a new line

      read -p "Are you sure you want to remove these? [y/N] " -n 1 -r

      echo    # move to a new line

      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Remove cancelled."
        return 1
      fi

      {
        head -n1 "$file"
        tail -n +2 "$file" | grep -vF -- "$*"
      } > "$file.tmp" && mv "$file.tmp" "$file"
      ;;

    show)
      list "$name" sort
      ;;

    sort)
      local index arrow field header orig_lines sort_lines
      local -a fields

      field="$1"
      header=$(head -n1 "$file")
      arrow=$(sed 's/↓.*//' <<< "$header" | tr -cd ',')
      index=$((${#arrow} + 1))
      IFS=',' read -r -a fields <<< "${header//↓/}"

      for i in "${!fields[@]}"; do
        [[ "${fields[i]}" == "$field" ]] && index=$((i+1)) && break
      done

      field="${fields[$((index-1))]}"
      fields[$((index-1))]+="↓"

      (IFS=','; echo "${fields[*]}") > "$file.tmp"
      tail -n +2 "$file" | sort -t, -k${index},${index} >> "$file.tmp"

      orig_lines=$(wc -l < "$file")
      sort_lines=$(wc -l < "$file.tmp")

      if [[ $orig_lines -eq $sort_lines ]]; then
        mv "$file.tmp" "$file"
        column -t -s, "$file"
      else
        echo "Error resorting ${name}"
        rm -f "$file.tmp"
        return 1
      fi
      ;;

    find)
      {
        head -n1 "$file"
        tail -n +2 "$file" | grep -F -- "$*"
      } | column -t -s,
     ;;

    filter)
      local filter

      filter="$*"
      
      list "$name" export "$filter" | column -t -s,
      ;;

    sum)
      local col filter tmpfile header index found total

      col="$1"
      shift
      filter="$*"
      tmpfile=$(mktemp)

      # Get filtered data, convert back to CSV
      list "$name" export "$filter" > "$tmpfile"

      # Find column index using comma as separator
      header=$(head -n1 "$file")
      IFS=',' read -r -a fields <<< "${header//↓/}"

      found=0
      for i in "${!fields[@]}"; do
        field=$(echo "${fields[i]}" | xargs)
        if [[ "$field" == "$col" ]]; then
          index=$i
          found=1
          break
        fi
      done

      if [[ $found -eq 0 ]]; then
        echo "Column '$col' not found."
        rm -f "$tmpfile"
        return 1
      fi

      # Sum the column (handle CSV)
      total=$(awk -v idx=$((index+1)) -F ',' '
        NR > 1 {
          gsub(/^ +| +$/, "", $idx)
          if ($idx ~ /^[0-9.]+$/) sum += $idx
        }
        END { print sum+0 }
      ' "$tmpfile")

      column -t -s, "$tmpfile"
      echo -e "\nTOTAL: $total"
      rm -f "$tmpfile"
      ;;

    fields)
      local header

      header=$(head -n1 "$file")

      echo "${header//↓/}"
      ;;

    import)
      local import header line
      local -a fields from

      import="$1"
      header=$(head -n1 "$file")
      IFS=',' read -r -a fields <<< "${header//↓/}"
      IFS=',' read -r -a from < <(head -n1 "$import")

      if [[ -z "$import" ]]; then
        echo "Usage: list $name import file"
        return 1
      fi

      if [[ -f "$import" ]]; then
        tail -n +2 "$import" | while IFS= read -r line; do
          list "$name" add "$line"
        done
      else
        echo "Import file '$import' does not exist."
      fi
      ;;

    export)
      local filter header expr colname
      local -a fields

      filter="$*"

      if [[ -z "$filter" ]]; then
        cat "$file"
        return
      fi

      header=$(head -n1 "$file")
      IFS=',' read -r -a fields <<< "${header//↓/}"

      expr="$filter"

      for i in "${!fields[@]}"; do
        colname="${fields[$i]}"
        expr=$(echo "$expr" | sed -E "s/\\b${colname}\\b/\\\$$((i+1))/g")
      done

      expr=$(echo "$expr" | sed -E 's/\band\b/&&/gi; s/\bor\b/||/gi')
      expr=$(echo "$expr" | sed -E 's/([^!><])=([^=])/\1==\2/g')
      expr=$(echo "$expr" | sed -E 's/([<>]=?|==|!=)[[:space:]]*([0-9]{4}-[0-9]{2}-[0-9]{2})/\1"\2"/g')
      expr=$(echo "$expr" | sed -E 's/(\$[0-9]+)[[:space:]]*([<>]=?|==|!=)[[:space:]]*("[^"]*"|[0-9.]+)/(\1 != "" \&\& \1 \2 \3)/g')

      echo "$header"
      awk -F, "NR>1 { for(i=1;i<=NF;i++) gsub(/^ +| +$/, \"\", \$i); if ($expr) print \$0 }" "$file"
      ;;

    json)
      local data header first
      local -a fields

      data=$(tail -n +2 "$file")
      header=$(head -n1 "$file")
      IFS=',' read -r -a fields <<< "${header//↓/}"

      echo "["

      while IFS=',' read -r -a row; do
        if [[ $first -eq 0 ]]; then
          echo ","
        fi

        first=0

        echo "  {"

        for i in "${!fields[@]}"; do
          local key val

          key=${fields[i]}
          val=${row[i]//\"/\\\"}

          echo "    \"$key\": \"$val\""$( [[ $i -lt $((${#fields[@]} - 1)) ]] && echo "," )
        done

        echo "  }"
      done <<< "$data"

      echo "]"
      ;;

    clear)
      head -n1 "$file" > "$file.tmp" && mv "$file.tmp" "$file"
      ;;

    help|*)
      echo "
  Usage: list name command [fields...]

  Commands:

    define fields...        Define or redefine list columns
    fields                  Show list columns
    add fields...           Add a new entry (fails if key exists)
    update fields...        Update (or add) entry by key (first field)
    remove pattern          Remove entries matching pattern
    show                    Show the list as-is
    edit                    Edit the list CSV directly
    sort field              Sort list by specified field (persists)
    find pattern            Find entries containing pattern
    filter 'pattern'        Filter by pattern (make sure to quote pattern)
    sum field 'pattern'     Sums field filtered by pattern (make sure to quote pattern)
    clear                   Remove all entries
    import file             Import entries from CSV
    export 'pattern'        Export the list to CSV
    json                    Export the list to JSON
    alias                   Create an alias for 'list name'
    help                    Show this help message
      "
      ;;
  esac
}

list domains alias
list business alias
list subcost alias

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
  cd - >/dev/null
}

function x() {
    [ -n "$COMP_CWORD" ] && set "${COMP_WORDS[@]:1:$COMP_CWORD}"

    COMPREPLY=( $(compgen -W ".. $(
      $(
        IFS=/;
        set "${1/#~/$HOME}" "${@:2}"
        echo "$*" 2>/dev/null | \
        sed -E 's|^(/)?(.*/)?(.*)$|ls -d \1./\2/\3*/|; s|\.\.\*/$|..|'
      ) 2>/dev/null | sed 's|^\(.*/\)\?\([^/]\+\)/\?|\2|'
    )"  -- "${@:$#}") )

    [ -z "$COMP_CWORD" ] && echo "${COMPREPLY[@]}"
}

function mkx() {
  eval 'function '$1'(){
    [ -z "$COMP_CWORD" ] && '$2' "'$3'" "${@}" && return

    ((COMP_CWORD++))
    COMP_WORDS=( "'$1'" "'$3'" "${COMP_WORDS[@]:1}" )

    x
  }'
  complete -F "$1" "$1"
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

function g..() {
  local dir="$(git rev-parse --show-toplevel 2>/dev/null || echo '.')"

  [ -z "$COMP_CWORD" ] && cdx "$dir" "${@}" && return

  ((COMP_CWORD++))
  COMP_WORDS=( x "$dir" "${COMP_WORDS[@]:1}" )

  x
}

function -() {
  [ -n "$1" ] && pushd "$1" && return
  dirs -p | grep -q '^/' && popd || cd -
  dirs -p | tail -n +2
}

declare -A BOOKMARKS

function --() {
  for i in "$@"; do
    local dir="$(realpath "$i" 2>/dev/null)"

    [ -d "$dir" ] && ! [[ " ${BOOKMARKS[*]} " =~ " ${dir} " ]] && BOOKMARKS+=("$dir")
  done

  for i in "${!BOOKMARKS[@]}"; do
    echo "$((i + 1)): ${BOOKMARKS[$i]/#$HOME/\~}"
  done
}

function -.() {
  -- "$PWD"
}

for i in {1..9}; do
  eval "function -$i(){ cd \"\${BOOKMARKS[$i-1]}\" 2>/dev/null; }"
  eval "function --$i(){ unset BOOKMARKS[$i-1] 2>/dev/null;BOOKMARKS=( \"\${BOOKMARKS[@]}\" ); }"
done

complete -F x x
complete -F x cdx
complete -F x mkcd
complete -F g.. g..

mkx wk mkcd ~/Work/
mkx .. cdx ../
mkx ... cdx ~/

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

  for x in $(\ls -d */ 2>/dev/null); do
    alias g.${x%/}="cdx $PWD/$x";
    echo g.${x%/}
  done

  cd -
}

function git_fix() {
  if [ $# -lt 1 ]; then
    echo "Usage: g.fix <old-email>"
    return 1
  fi
  local old_email="$1"
  local current_name=$(git config user.name)
  local current_email=$(git config user.email)

  echo "Beginning replacement of '$old_email'  to '$current_name <$current_email>'."

  git filter-branch --env-filter '
    if [ "$GIT_AUTHOR_EMAIL" = "'"$old_email"'" ]; then
      export GIT_AUTHOR_NAME="'"$current_name"'"
      export GIT_AUTHOR_EMAIL="'"$current_email"'"
    fi
    if [ "$GIT_COMMITTER_EMAIL" = "'"$old_email"'" ]; then
      export GIT_COMMITTER_NAME="'"$current_name"'"
      export GIT_COMMITTER_EMAIL="'"$current_email"'"
    fi
  ' --tag-name-filter cat -- --all >/dev/null 2>&1

  echo "Done! All commits with email '$old_email' have been changed to '$current_name <$current_email>'."
}


function v.() {
  unalias $(alias|grep "alias v\."|cut -d"=" -f1|cut -d" " -f2) &> /dev/null

  for x in $(\ls -d */ 2>/dev/null); do
    alias v.${x%/}="unset VFILES;cdrun '$PWD/$x' v";
    echo v.${x%/}
  done
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

  docker build -t tester .

  opt=()
  cmd=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --) shift; cmd=("$@"); break ;;
      *) opt+=("$1"); shift ;;
    esac
  done

  docker rm -f tester &>/dev/null
  docker run -it "${opt[@]}" --name tester tester "${cmd[@]}"
}

alias dps="docker ps -a -q"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcr="docker compose run -it"
alias dcl="docker compose logs"
alias dca="dcd&&dcu"

# alias if nhost not setup
type -p nhost > /dev/null || alias nhost="rash https://raw.githubusercontent.com/nhost/cli/main/get.sh && unalias nhost && nhost"

function run-or-install () {
  local prog=$1

  type -p $prog > /dev/null || alias $prog="install-$prog && unalias $prog && $prog"

  if [ -z "$(type -t install-$prog)" ]; then
    alias inatall-$prog="apt install $prog -y"
  fi
}

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

  sudo groupadd -f docker
  sudo usermod -aG docker $USER
  newgrp docker
}

function install-psql() {
  local VERSION=$(. /etc/os-release && echo "$VERSION_CODENAME")

  # Add PostgreSQL's official GPG key:
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

install-go() {
  local version

  version=$(wget -qO- 'https://go.dev/dl/?mode=json' | grep -m1 -oP '"version":\s*"\Kgo[0-9.]+' | sed 's/^go//')

  wget -P /tmp "https://go.dev/dl/go${version}.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "/tmp/go${version}.linux-amd64.tar.gz"
}

run-or-install psql
run-or-install docker
run-or-install jq
run-or-install whois
run-or-install ncat
run-or-install go

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

  sudo apt install ncat -y

  (
    local I="0"

    while [ $I -lt 12 ];do
      I=$[$I+1]
      echo -e "HTTP/1.1 200\r\nContent-Type:text/html\r\n\r\nFRINGPONG $I" | ncat -lv 1234 2>&1
    done >/dev/null &
  )
}

function completer() {
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

git.id() {
  local usage="Usage: git.id [nickname] [email] [name]"
  local nickname="$1"
  local email="$2"
  local name="${@:3}"
  local keyfile="$HOME/.ssh/$nickname"
  local pubfile="$keyfile.pub"

  if [[ -z "$nickname" ]]; then
    echo "$usage"
    return 1
  fi

  if [[ -f "$pubfile" ]]; then
    local existing_comment=$(sed 's/^[^ ]* [^ ]* //' "$pubfile")

    if [[ -n "$email" && -n "$name" ]]; then
      local new_comment="$name <$email>"

      if [[ "$existing_comment" != "$new_comment" ]]; then
        echo "Updating comment on existing key $nickname..."
        ssh-keygen -c -C "$new_comment" -f "$keyfile"
      fi
    fi
  elif [[ -n "$email" && -n "$name" ]]; then
    ssh-keygen -t ed25519 -C "$name <$email>" -f "$keyfile"
  else
    echo "$usage"
    return 1
  fi

  if command git rev-parse --show-toplevel &>/dev/null; then
    local comment=$(sed 's/^[^ ]* [^ ]* //' "$pubfile")
    local config_email=$(echo "$comment" | sed -n 's/.*<\(.*\)>.*/\1/p')
    local config_name=$(echo "$comment" | sed -n 's/\(.*\) <.*>/\1/p')

    if [[ -n "$config_email" && -n "$config_name" ]]; then
      command git config user.email "$config_email"
      command git config user.name "$config_name"
    else
      echo "Malformed Public Key run: git.id $nickname email name"
      return 1
    fi
  fi

  cat "$pubfile"
}

git.as() {
  local nickname="$1"
  shift

  if [[ "$1" == "clone" ]]; then
    local repo_url="$2"
    local dir_name="$3"

    # Use 'command git' to avoid recursion
    GIT_SSH_COMMAND="ssh -i $HOME/.ssh/$nickname -o IdentitiesOnly=yes" command git clone "$repo_url" $dir_name

    local target_dir
    if [[ -n "$dir_name" ]]; then
      target_dir="$dir_name"
    else
      target_dir=$(basename "$repo_url" .git)
    fi

    if [[ -d "$target_dir/.git" ]]; then
      (
        cd "$target_dir"
        git.id "$nickname"
      )
    else
      echo "Target directory not found: $target_dir"
      return 1
    fi
  elif [[ "$1" == "init" ]]; then
    command git "$@"
    git.id "$nickname"
  else
    GIT_SSH_COMMAND="ssh -i $HOME/.ssh/$nickname -o IdentitiesOnly=yes" command git "$@"
  fi
}

git() {
  local email=$(command git config user.email)
  if [[ -z "$email" ]]; then
    echo "git.id not set. Use git.id to configure this repository."
    return 1
  fi

  # Find the SSH key nickname by grepping .ssh/*.pub for the email
  local pubfile=$(grep -l "$email" ~/.ssh/*.pub 2>/dev/null | head -n1)
  if [[ -z "$pubfile" ]]; then
    echo "git.id misconfigured. Use git.id to fix this repository."
    return 1
  fi

  git.as "$(basename "$pubfile" .pub)" "$@"
}

ssh.as() {
  local nickname="$1"
  shift
  ssh -i "$HOME/.ssh/$nickname" -o IdentitiesOnly=yes "$@"
}

localalias() {
  local nickname="$1"
  shift

  local alias_cmd="alias $nickname='$*'"
  local rcfile="$HOME/.localrc"

  grep -v "^alias $nickname=" "$rcfile" 2>/dev/null > "$rcfile.tmp" || true
  echo "$alias_cmd" >> "$rcfile.tmp"
  mv "$rcfile.tmp" "$rcfile"
  source "$rcfile"

  echo "Alias '$nickname' updated: $alias_cmd"
}

[ -f ~/.localrc ] && source ~/.localrc

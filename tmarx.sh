#!/bin/bash

function tmarx() {

    if [ $# -eq 0 ]; then
        echo "tmarx: no subcommand provided"
        tmarx-help
        return 1
    fi

    case "$1" in
        mark | m)
            case $2 in
                "-g")
                    MARKPWD=".*"
                    tmarx-mark ${@:3}
                    ;;
                *)
                    MARKPWD=$PWD
                    tmarx-mark ${@:2}
                    ;;
            esac
            ;;
        attach | a)
            tmarx-attach ${@:2}
            ;;
        run | x)
            tmarx-run ${@:2}
            ;;
        edit | e)
            tmarx-edit ${@:2}
            ;;
        cat)
            tmarx-cat ${@:2}
            ;;
        "-h" | "--help" | help | h)
            tmarx-help
            ;;
        *)
            echo "tmarx: unknown subcommand '$1'"
            tmarx-help
            return 1
            ;;
    esac
}

tmarx-help() {
    echo "usage: tmarx <subcommand> [options]"
    echo ""
    echo "Subcommands:"
    echo "  mark     Bookmark a command"
    echo "  attach   Attach aliases to session"
    echo "  run      Execute an alias"
    echo "  edit     Open bookmarks on '$EDITOR'"
    echo "  cat      Cat bookmarks file"
    echo "  help     Show this help message"
}

tmarx-file() {
    export TMARXFILE=${TMARXFILE:-$HOME/.local/share/tmarx/bookmarks.txt}
}

tmarx-run() {
    if [ "$#" -eq 0 ] || [ $1 = '-h' -o $1 = '--help' ]; then
        echo "usage: tmarx run <name> [options]"
        return 1
    fi

    tmarx-file

    prefix="$PWD $1"

    if [ -f $TMARXFILE ]; then

        commd=$(cat $TMARXFILE | \grep -h ".*\bh\b.*" | awk -v PWD=$PWD '
            { gsub("/","\\/", $1) }
            PWD ~ $1 {
                $1=""
                $2=""
                print $0
            }
        ' - | awk 'NR==1 {print; exit}' -)
    fi

    if [ -z "$commd" ]; then
        if command -v "\\$1" 2>&1 >/dev/null; then
            command $1
            return $?
        else
            echo "$1: command not found"
            return 1
        fi
    fi
    opts=${@#"$1"}
    eval "$commd $opts"
}

tmarx-attach() {
    if [ "$#" -ne 0 ]; then 
        echo "tmarx attach: no options available."
        return 1
    fi
    tmarx-file
    if [ -f $TMARXFILE ]; then
        awkscript='{ printf "alias %s=\"tmarx-run %s\"\n", $2, $2 }'
        shscript=$(awk "$awkscript" "$TMARXFILE" | sort -u)
        eval $shscript    
    fi
    
}

tmarx-mark() {
    if [ $# -ge 2 ]; then
        tmarx-file
        command mkdir -p "${TMARXFILE%/*}/"
        echo "$MARKPWD $@" >> "$TMARXFILE"
        echo "Mark set as '$1' at $MARKPWD"
    else
        echo "usage: tmarx mark [-g] <name> \"<command>\""
    fi
    tmarx-attach
}

tmarx-cat() {
    if [ "$#" -ne 0 ]; then 
        echo "tmarx cat: no options available."
        return 1
    fi
    tmarx-file
    if [ -f $TMARXFILE ]; then
        command cat $TMARXFILE
    fi
}

tmarx-edit() {
    if [ "$#" -ne 0 ]; then 
        echo "tmarx edit: no options available."
        return 1
    fi
    tmarx-file
    command mkdir -p "${TMARXFILE%/*}/"
    "${VISUAL:-"${EDITOR:-vim}"}" $TMARXFILE
}







#!/bin/bash -e

#
# mkalias 1.0.0 - automatic lazy Bash completion for aliases
#
# Copyright (C) 2024  Piotr Henryk Dabrowski <phd@phd.re>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, see
# <https://www.gnu.org/licenses/>.
#

[ -f /etc/bash_completion ] && source /etc/bash_completion

declare -A __mkalias_commands

function mkalias {
    if [ -z "$1" ]; then     # no arguments
        __mkalias_print_all  # print all aliasses
        return 0
    fi
    if [ "$1" = "-p" ]; then                                              # -p [NAME]
        [ -n "$2" ] && __mkalias_print_alias "$2" || __mkalias_print_all  # print one or all aliases
        return 0
    fi
    if [ "$1" = '--help' ] || [ "$1" = '-h' ]; then  # --help or -h
        __mkalias_help                               # print help
        return 0
    fi

    local Name="$1"     # the Name of the alias (required)
    local Syntax="$2"   # new Syntax for alias (optional)
    local Command="$3"  # Command to complete the alias like (optional)

    if [ -n "${Syntax}" ]; then                # was Syntax given in arguments?
        alias -- "$Name"="$Syntax"             # yes -> define a new alias
    else
        Syntax=$(alias "${Name}" 2>/dev/null)  # no -> get the current Syntax from existing alias
        Syntax="${Syntax#*=\'}"
        Syntax="${Syntax%\'}"
        if [ -z "${Syntax}" ]; then            # still no Syntax -> error:
            echo 'mkalias: error: no new syntax given, but alias does not exist' >&2
            return 1
        fi
    fi

    if [ -z "${Command}" ]; then      # was Command given in arguments?
        Command=""${Syntax%% *}""     # no -> get the first word of alias' Syntax as the Command
        if [ -z "${Command}" ]; then  # still no Command -> error:
            echo 'mkalias: error: command not given and cannot be decucted form the existing alias' >&2
            return 2
        fi
    fi

    __mkalias_commands["${Name}"]="${Command}"  # save the Command

    if [ "${Command}" = "${Name}" ]; then  # exit if the alias' Name is the same as the Command
        return 0
    fi

    command -v 'complete' &>/dev/null || return 3       # do we have 'complete'? no -> error
    eval "complete -F __mkalias_lazy_complete ${Name}"  # temporarly assign the lazy completion function for this alias
}

function __mkalias_lazy_complete {
    local Name="$1"               # the Name of the alias currently being completed by this proxy function
    [ -z "${Name}" ] && return 0  # exit if unknown

    local Command="${__mkalias_commands[$Name]}"  # get the saved Command for this alias
    [ -z "${Command}" ] && return 0               # exit if unknown
    _completion_loader "${Command}"               # load bash completion for the Command

    local completion=$(complete -p ${Command} || true)  # get 'complete' command string for the Command
    [ -z "${completion}" ] && return 0                  # exit if 'complete' command string is unknown
    eval "${completion% *} ${Name}"                     # replace the Command with alias' Name, and then run 'complete'
                                                        # to reassign the completion function and options for this alias

    local func
    local REGEX=' -F ([^ ]+) '                     # regex: get the value of the '-F' argument from the 'complete' command
    if [[ "${completion}" =~ ${REGEX} ]]; then
        func="${BASH_REMATCH[1]}"                  # get the function name used by Bash for Command's completion
    fi
    [ -z "${func}" ] && return 0                   # exit if failed to get the function name
    [ "${func}" = "__lazy_complete" ] && return 0  # exit if completion function points back to here

    local options=$(compopt ${Command} || true)  # get the completion options for the Command
    eval "${options% *}"                         # remove Command's name (last) and run 'compopt' to set options here
    "${func}" $@                                 # this one time run the original function with its options set
}

function __mkalias_print_all {
    local Name Name2
    for Name in "${!__mkalias_commands[@]}"; do
        echo $Name
    done |
        sort |
        while read -r Name2; do
            __mkalias_print_alias "$Name2"
        done
}

function __mkalias_print_alias {
    local Name="$1"
    local Command="${__mkalias_commands[$Name]}"
    echo "$(alias $Name 2>/dev/null || echo "alias ${Name} does not exist") (${Command:-not completion-enabled})"
}

function __mkalias_help {
    cat <<EOF
Usage:
    mkalias NAME [SYNTAX [COMMAND]]
    mkalias [-p [NAME]]
    mkalias (--help|-h)

    Automatic lazy Bash completion for aliases.

    NAME       The Name of the alias, required.
    SYNTAX     New syntax for alias, optional.
               If given, mkalias creates a new alias NAME for that syntax.
               If not given, it gets the current syntax from the existing alias
               or returns an error.
    COMMAND    Command to complete alias like, optional.
               If given, mkalias notifies Bash completion to complete the alias
               like it was this command.
               If not given, mkalias deduces the command to act as from the
               first word of the alias' syntax.
    -p [NAME]  Print the alias, its syntax and associated completion command.
               With no arguments print all completion-enabled aliases.

    Calling mkalias on an existing alias again will simply redefine it and/or
    overwrite its completion settings.

EOF
#1111111112222222222333333333344444444445555555555666666666677777777778888888888
}

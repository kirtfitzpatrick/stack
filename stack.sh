#!/usr/bin/env bash

VERSION=0.0.1

usage () {
  echo "stack [-hV]"
  echo
  echo "Options:"
  echo "  -h|--help      Print this help dialogue and exit"
  echo "  -V|--version   Print the current version and exit"
}

# A stack, using bash arrays.
# ---------------------------------------------------------------------------

# Create a new stack.
#
# Usage: stack_new name
#
# Example: stack_new x
function stack_new {
    : ${1?'Missing stack name'}
    if stack_exists $1
    then
        echo "Stack already exists -- $1" >&2
        return 1
    fi

    eval "declare -ag _stack_$1"
    eval "declare -ig _stack_$1_i"
    eval "let _stack_$1_i=0"
    return 0
}

# Destroy a stack
#
# Usage: stack_destroy name
function stack_destroy {
    : ${1?'Missing stack name'}
    eval "unset _stack_$1 _stack_$1_i"
    return 0
}

# Push one or more items onto a stack.
#
# Usage: stack_push stack item ...
function stack_push {
    : ${1?'Missing stack name'}
    : ${2?'Missing item(s) to push'}

    if no_such_stack $1
    then
        echo "No such stack -- $1" >&2
        return 1
    fi

    stack=$1
    shift 1

    while (( $# > 0 ))
    do
        eval '_i=$'"_stack_${stack}_i"
        eval "_stack_${stack}[$_i]='$1'"
        eval "let _stack_${stack}_i+=1"
        shift 1
    done

    unset _i
    return 0
}

# Print a stack to stdout.
#
# Usage: stack_print name
function stack_print {
    : ${1?'Missing stack name'}

    if no_such_stack $1
    then
        echo "No such stack -- $1" >&2
        return 1
    fi

    tmp=""
    eval 'let _i=$'_stack_$1_i
    while (( $_i > 0 ))
    do
        let _i=${_i}-1
        eval 'e=$'"{_stack_$1[$_i]}"
        tmp="$tmp $e"
    done
    echo "(" $tmp ")"
}

# Get the size of a stack
#
# Usage: stack_size name var
#
# Example:
#    stack_size mystack n
#    echo "Size is $n"
function stack_size {
    : ${1?'Missing stack name'}
    : ${2?'Missing name of variable for stack size result'}
    if no_such_stack $1
    then
        echo "No such stack -- $1" >&2
        return 1
    fi
    eval "$2"='$'"{#_stack_$1[*]}"
}

# Pop the top element from the stack.
#
# Usage: stack_pop name var
#
# Example:
#    stack_pop mystack top
#    echo "Got $top"
function stack_pop {
    : ${1?'Missing stack name'}
    : ${2?'Missing name of variable for popped result'}

    eval 'let _i=$'"_stack_$1_i"
    if no_such_stack $1
    then
        echo "No such stack -- $1" >&2
        return 1
    fi

    if [[ "$_i" -eq 0 ]]
    then
        echo "Empty stack -- $1" >&2
        return 1
    fi

    let _i-=1
    eval "$2"='$'"{_stack_$1[$_i]}"
    eval "unset _stack_$1[$_i]"
    eval "_stack_$1_i=$_i"
    unset _i
    return 0
}

function no_such_stack {
    : ${1?'Missing stack name'}
    stack_exists $1
    ret=$?
    declare -i x
    let x="1-$ret"
    return $x
}

function stack_exists {
    : ${1?'Missing stack name'}

    eval '_i=$'"_stack_$1_i"
    if [[ -z "$_i" ]]
    then
        return 1
    else
        return 0
    fi
}


stack () {
  local opt="$1"
  local cmd=""
  shift

  case "${opt}" in
    -h|--help)
      usage
      return 0
      ;;
    -V|--version)
      echo "$VERSION"
      return 0
      ;;
    *)
      cmd="stack_${opt}"
      if type "${cmd}" > /dev/null 2>&1; then
        "${cmd}" "${@}"
        return $?
      else
        if [ ! -z "${opt}" ]; then
          error "Unknown argument: \`${opt}'"
        fi
        usage
        return 1
      fi
      ;;
  esac
}

if [[ ${BASH_SOURCE[0]} != $0 ]]; then
  export -f stack
else
  stack "${@}"
  exit $?
fi
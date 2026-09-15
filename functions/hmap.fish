function hmap --no-scope-shadowing
    argparse --stop-nonopt h/help -- $argv
    or return

    if set -q _flag_help; or test (count $argv) -eq 0
        __hmap_help
        return 0
    end

    switch $argv[1]
        case new set get has unset assign merge clear keys values length
            __hmap_$argv[1] $argv[2..]
        case '*'
            echo "hmap: unknown subcommand '$argv[1]'" >&2
            return 1
    end
end

function __hmap_help
    echo "hmap [-h|--help]"
    echo "hmap new NAME"
    echo "hmap set MAP KEY [VALUE...]"
    echo "hmap get MAP KEY [DEFAULT]"
    echo "hmap has MAP KEY"
    echo "hmap unset MAP KEY"
    echo "hmap assign MAP [KEY VALUE ...]"
    echo "hmap merge DESTINATION SOURCE"
    echo "hmap clear MAP"
    echo "hmap keys MAP"
    echo "hmap values MAP"
    echo "hmap length MAP"
    echo
    echo "Examples:"
    echo "    hmap new foo"
    echo "    hmap set \$foo name Joel"
    echo "    hmap get \$foo name"
end

function __hmap_require_live -a operation handle --no-scope-shadowing
    if not __hmap_is_live $handle
        echo "hmap $operation: '$handle' is not an hmap" >&2
        return 1
    end

    return 0
end

# new writes into the caller's scope, so reserve names that could collide
# with function, argparse, or implementation variables.
function __hmap_new -a __hmap_name --no-scope-shadowing
    argparse -n 'hmap new' -N 1 -X 1 -s -- $argv
    or return

    if not string match -qr '^[A-Za-z0-9_]+$' -- "$__hmap_name"
        echo "hmap new: invalid NAME '$__hmap_name'" >&2
        return 1
    end

    if string match -qr '^(argv|argv_opts|_flag_.*|__hmap_.*)$' -- "$__hmap_name"
        echo "hmap new: reserved NAME '$__hmap_name'" >&2
        return 1
    end

    if set -q $__hmap_name
        echo "hmap new: '$__hmap_name' already exists" >&2
        return 1
    end

    set --local __hmap_handle (__hmap_handle)
    set -- $__hmap_name $__hmap_handle
    set {$__hmap_handle}_registered 1
    set {$__hmap_handle}_keys

    return 0
end

function __hmap_set -a handle key --no-scope-shadowing
    argparse -n 'hmap set' -N 2 -s -- $argv
    or return

    __hmap_require_live set $handle; or return

    set --local keys {$handle}_keys
    set --local entry (__hmap_entry_variable $handle $key)

    set -q $entry; or set -a -- $keys $key

    set -- $entry $argv[3..]
    return 0
end

function __hmap_get -a handle key default --no-scope-shadowing
    argparse -n 'hmap get' -N 2 -X 3 -s -- $argv
    or return

    __hmap_require_live get $handle; or return

    set --local entry (__hmap_entry_variable $handle $key)

    if not set -q $entry
        if test (count $argv) -eq 3
            printf '%s\n' $default
            return 0
        end

        return 1
    end

    set -q {$entry}[1]; and printf '%s\n' $$entry

    return 0
end

function __hmap_has -a handle key --no-scope-shadowing
    argparse -n 'hmap has' -N 2 -X 2 -s -- $argv
    or return

    __hmap_require_live has $handle; or return

    set --local keys {$handle}_keys
    contains -- $key $$keys
end

function __hmap_unset -a handle key --no-scope-shadowing
    argparse -n 'hmap unset' -N 2 -X 2 -s -- $argv
    or return

    __hmap_require_live unset $handle; or return

    set --local keys {$handle}_keys
    set -e (__hmap_entry_variable $handle $key)

    set --local index (contains --index -- $key $$keys)
    test -n "$index"; and set -e {$keys}[$index]

    return 0
end

function __hmap_assign -a handle --no-scope-shadowing
    argparse -n 'hmap assign' -N 1 -s -- $argv
    or return

    __hmap_require_live assign $handle; or return

    if test (math (count $argv[2..]) % 2) -ne 0
        echo "hmap assign: expected KEY VALUE pairs" >&2
        return 1
    end

    if test (count $argv) -ge 3
        for index in (seq 2 2 (count $argv))
            __hmap_set $handle $argv[$index] $argv[(math $index + 1)]; or return
        end
    end

    return 0
end

function __hmap_merge -a destination source --no-scope-shadowing
    argparse -n 'hmap merge' -N 2 -X 2 -s -- $argv
    or return

    __hmap_require_live merge $destination; or return
    __hmap_require_live merge $source; or return

    set --local source_keys {$source}_keys
    for key in $$source_keys
        set --local entry (__hmap_entry_variable $source $key)
        __hmap_set $destination $key $$entry; or return
    end

    return 0
end

function __hmap_clear -a handle --no-scope-shadowing
    argparse -n 'hmap clear' -N 1 -X 1 -s -- $argv
    or return

    __hmap_require_live clear $handle; or return

    set --local keys {$handle}_keys
    for key in $$keys
        __hmap_unset $handle $key; or return
    end

    return 0
end

function __hmap_keys -a handle --no-scope-shadowing
    argparse -n 'hmap keys' -N 1 -X 1 -s -- $argv
    or return

    __hmap_require_live keys $handle; or return

    set --local keys {$handle}_keys
    set -q {$keys}[1]; and printf '%s\n' $$keys

    return 0
end

function __hmap_values -a handle --no-scope-shadowing
    argparse -n 'hmap values' -N 1 -X 1 -s -- $argv
    or return

    __hmap_require_live values $handle; or return

    set --local keys {$handle}_keys
    set --local vals

    for key in $$keys
        set --local entry (__hmap_entry_variable $handle $key)
        set -a -- vals $$entry
    end

    set -q vals[1]; and printf '%s\n' $vals

    return 0
end

function __hmap_length -a handle --no-scope-shadowing
    argparse -n 'hmap length' -N 1 -X 1 -s -- $argv
    or return

    __hmap_require_live length $handle; or return

    set --local keys {$handle}_keys
    printf '%s\n' (count $$keys)
end

function __hmap_handle
    set -q __hmap_sequence; or set -g __hmap_sequence 0

    set -g __hmap_sequence (math $__hmap_sequence + 1)
    echo __hmap_{$fish_pid}_$__hmap_sequence
end

function __hmap_is_live -a handle --no-scope-shadowing
    string match -qr '^__hmap_[A-Za-z0-9_]+$' -- "$handle"; or return 1
    set -q {$handle}_registered
end

function __hmap_entry_variable -a handle key
    echo {$handle}_entry_(string escape --style=var -- $key)
end

function hmap --no-scope-shadowing
    argparse h/help -- $argv
    or return

    if set -q _flag_help; or test (count $argv) -eq 0
        __hmap_constructor_help; and return
    end

    if test (count $argv) -ne 2
        echo "hmap: expected: hmap new NAME" >&2
        return 1
    end

    switch $argv[1]
        case new
            __hmap_new $argv[2..]
        case '*'
            echo "Unknown command: $argv[1]"
            __hmap_constructor_help; and return 1
    end
end

function __hmap_constructor_help
    echo "hmap [-h|--help] -- Display help"
    echo "hmap new <NAME>  -- Create hmap called <NAME>"
end

function __hmap_new --no-scope-shadowing
    set --local hmap_name $argv[1]

    if test -z "$hmap_name"
        echo "hmap new: expected NAME" >&2
        return 1
    end

    if __is_live_hmap
        echo "hmap new: '$hmap_name' already exists" >&2
        return 1
    end

    # name may have gone out of scope and left stale proxy function
    # if type resolves to stale proxy we can overwrite it
    if type -q $hmap_name; and not __is_hmap_proxy
        echo "hmap new: command '$hmap_name' already exists" >&2
        return 1
    end

    function $hmap_name --description __hmap_proxy --no-scope-shadowing
        set --local hmap_name (status current-function)

        # variable is dereferenced and proxy still in global scope
        # unset proxy function and fail
        if not __is_live_hmap
            echo "$hmap_name: hmap is out of scope" >&2
            functions -e $hmap_name
            return 1
        end
        __hmap_dispatch $argv
    end

    # register function creation to detect scope leakage
    set (__hmap_registration_name) 1
end

function __hmap_dispatch -a operation --no-scope-shadowing
    set --local prefix (__hmap_variable_prefix)
    set --local keys "$prefix"_keys

    switch $operation
        case set
            __hmap_set $argv[2..]

        case get
            __hmap_get $argv[2..]; or return

        case has
            if test (count $argv) -lt 2; or test -z "$argv[2]"
                echo "$hmap_name: has expected KEY" >&2
                return 1
            end
            contains -- $argv[2] $$keys

        case assign
            __hmap_assign $argv[2..]

        case merge
            __hmap_merge $argv[2..]

        case unset
            __hmap_unset $argv[2..]

        case clear
            __hmap_clear

        case keys
            set -q {$keys}[1]; and printf '%s\n' $$keys

        case values
            __hmap_values

        case length
            printf '%s\n' (count $$keys)

        case '*'
            echo "$hmap_name: unknown operation '$operation'" >&2
            return 1
    end
end

function __hmap_set -a key --no-scope-shadowing
    if test -z "$key"
        echo "$hmap_name: set expected KEY" >&2
        return 1
    end

    set --local entry (__hmap_entry_variable $prefix $key)

    if not set -q $entry
        set -a $keys $key
    end

    set $entry $argv[2..]
end

function __hmap_get -a key default --no-scope-shadowing
    if test -z "$key"
        echo "$hmap_name: get expected KEY" >&2
        return 1
    end

    set --local entry (__hmap_entry_variable $prefix $key)

    if not set -q $entry
        test -n "$default"; and printf '%s\n' $default; and return
        or return
    end

    printf '%s\n' $$entry
end

function __hmap_assign --no-scope-shadowing
    if test (math (count $argv) % 2) -ne 0
        echo "$hmap_name: assign expected KEY VALUE pairs" >&2
        return 1
    end

    for i in (seq 1 2 (count $argv))
        __hmap_set $argv[$i] $argv[(math $i + 1)]
    end
end

function __hmap_merge --no-scope-shadowing
    set --local other $argv[1]

    if test -z "$other"
        echo "$hmap_name: merge expected NAME" >&2
        return 1
    end

    if not __is_named_live_hmap $other
        echo "$hmap_name: merge '$other' is not an hmap" >&2
        return 1
    end

    set --local other_keys ($other keys)

    for key in $other_keys
        set --local other_value ($other get $key)
        __hmap_set $key $other_value
    end
end

function __hmap_unset -a key --no-scope-shadowing
    if test -z "$key"
        echo "$hmap_name: unset expected KEY" >&2
        return 1
    end

    set --local entry (__hmap_entry_variable $prefix $key)
    set -e $entry

    set --local index (contains --index -- $key $$keys)
    if test -n "$index"
        set -e {$keys}[$index]
    end
end

function __hmap_clear --no-scope-shadowing
    for key in $$keys
        __hmap_unset $key
    end
end

function __hmap_values --no-scope-shadowing
    set --local vals

    for key in $$keys
        set --local entry (__hmap_entry_variable $prefix $key)
        set -a vals $$entry
    end

    if test (count $vals) -gt 0
        printf '%s\n' $vals
    end
end

function __hmap_entry_variable -a prefix key
    echo "$prefix"_entry_(__normalise_hmap_variable_string $key)
end

# Proxy and lifecycle machinery

function __is_live_hmap --no-scope-shadowing
    set -q (__hmap_registration_name)
end

function __hmap_registration_name --no-scope-shadowing
    echo (__hmap_variable_prefix)_registered
end

function __hmap_variable_prefix --no-scope-shadowing
    set --local normalised (__normalise_hmap_variable_string $hmap_name)
    echo "__hmap_$normalised"
end

function __normalise_hmap_variable_string
    string escape --style=var -- $argv[1]
end

function __is_hmap_proxy --no-scope-shadowing
    functions -q $hmap_name; or return

    set --local details (functions --details --verbose $hmap_name)

    test "$details[5]" = __hmap_proxy
end

function __is_named_live_hmap -a name --no-scope-shadowing
    set --local hmap_name $name
    functions -q $hmap_name; or return 1
    __is_hmap_proxy; or return 1
    __is_live_hmap
end

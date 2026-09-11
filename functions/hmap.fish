function hmap --no-scope-shadowing
    argparse h/help -- $argv
    or return

    if set -q _flag_help; or test (count $argv) -eq 0
        __hmap_constructor_help; and return
    end

    if test (count $argv) -ne 2
        echo "hmap: expected: hmap new NAME" >&2
        return 2
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
    set --local name $argv[1]

    if test -z "$name"
        echo "hmap new: expected NAME" >&2
        return 1
    end

    if set -q $name
        echo "hmap new: variable '$name' already exists" >&2
        return 1
    end

    # name may have gone out of scope and left stale proxy function
    # if type resolves to stale proxy we can overwrite it
    if type -q $name; and not __is_hmap_proxy
        echo "hmap new: command '$name' already exists" >&2
        return 1
    end

    function $name --description __hmap_proxy --no-scope-shadowing
        set --local hmap (status current-function)
        set --local registered "__hmap_$hmap"_registered

        # variable is dereferenced and proxy still in global scope
        # unset proxy function and fail
        if not set -q $registered
            echo "$hmap: hmap is out of scope" >&2
            functions -e $hmap
            return 1
        end
        __hmap_dispatch $argv
    end

    # register function to detect scope leakage
    set "__hmap_$name"_registered 1
    set "__hmap_$name"_keys
end

function __is_hmap_proxy --no-scope-shadowing
    functions -q $name; or return

    set --local details (functions --details --verbose $name)

    test "$details[5]" = __hmap_proxy
end

function __hmap_dispatch --no-scope-shadowing
    set --local operation $argv[1]

    set --local keys "__hmap_$hmap"_keys

    switch $operation
        case set
            set --local key $argv[2]
            set --local value $argv[3]

            set --local escaped (__normalise_hmap_key $key)
            set --local entry "__hmap_$hmap"_"$escaped"

            if not set -q $entry
                set -a $keys $key
            end

            set $entry $value

        case get
            set --local key $argv[2]
            set --local escaped (__normalise_hmap_key $key)
            set --local entry "__hmap_$hmap"_"$escaped"

            if not set -q $entry
                return 1
            end

            printf '%s\n' $$entry

        case keys
            printf '%s\n' $$keys

        case values
            set --local vals

            for key in $$keys
                set --local escaped (__normalise_hmap_key $key)
                set --local entry "__hmap_$hmap"_"$escaped"
                set -a vals $$entry
            end
            printf '%s\n' $vals

        case length
            printf '%s\n' (count $$keys)

        case '*'
            echo "$hmap: unknown operation '$operation'" >&2
            return 2
    end
end

function __normalise_hmap_key
    string escape --style=var -- $argv[1]
end

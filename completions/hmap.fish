function __hmap_live_map_names
    set -l __hmap_comp_name

    for __hmap_comp_name in (set -n)
        string match -q '__hmap_*' -- $__hmap_comp_name
        and continue

        __hmap_is_live $$__hmap_comp_name
        and printf '%s\n' $__hmap_comp_name
    end
end

function __hmap_complete_maps
    set -l names (__hmap_live_map_names | sort)
    set -q names[1]; or return 1

    set -l current (string replace -r '^\$' '' -- (commandline -ct))
    set -l index (contains --index -- $current $names)

    if test -n "$index"
        set index (math "$index % "(count $names)" + 1")
        commandline -rt -- \$$names[$index]
        return 0
    end

    set -l matches (string match -- "$current*" $names)
    set -q matches[1]; or return 1

    commandline -rt -- \$$matches[1]
end

function __hmap_tab
    if commandline -P
        commandline -f complete
        return
    end

    set -l tokens (commandline -xpc)

    if test "$tokens[1]" = hmap
        switch $tokens[2]
            case set get has unset assign clear keys values length
                test (count $tokens) -eq 2
                and __hmap_complete_maps
                and return

            case merge
                contains -- (count $tokens) 2 3
                and __hmap_complete_maps
                and return
        end
    end

    commandline -f complete
end

function __hmap_complete_keys
    set -l tokens (commandline -xpc)
    set -q tokens[3]; or return 1

    set -l handle $tokens[3]
    __hmap_is_live $handle; or return 1

    set -l keys {$handle}_keys
    set -q {$keys}[1]; and printf '%s\n' $$keys
end

complete -c hmap -f
complete -c hmap -n __fish_use_subcommand -s h -l help -d 'Print help'

complete -c hmap -n __fish_use_subcommand -a new -d 'Create an hmap'
complete -c hmap -n __fish_use_subcommand -a set -d 'Set a key'
complete -c hmap -n __fish_use_subcommand -a get -d 'Get a key'
complete -c hmap -n __fish_use_subcommand -a has -d 'Test a key'
complete -c hmap -n __fish_use_subcommand -a unset -d 'Remove a key'
complete -c hmap -n __fish_use_subcommand -a assign -d 'Set key-value pairs'
complete -c hmap -n __fish_use_subcommand -a merge -d 'Copy keys from a source'
complete -c hmap -n __fish_use_subcommand -a clear -d 'Remove all keys'
complete -c hmap -n __fish_use_subcommand -a keys -d 'Print keys'
complete -c hmap -n __fish_use_subcommand -a values -d 'Print values'
complete -c hmap -n __fish_use_subcommand -a length -d 'Count keys'

complete -c hmap \
    -n '__fish_seen_subcommand_from get has unset set' \
    -n 'test (count (commandline -xpc)) -eq 3' \
    -k \
    -a '(__hmap_complete_keys)'

complete -c hmap \
    -n '__fish_seen_subcommand_from assign' \
    -n 'test (math (count (commandline -xpc)) % 2) -eq 1' \
    -k \
    -a '(__hmap_complete_keys)'

bind tab __hmap_tab

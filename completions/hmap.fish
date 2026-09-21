function __hmap_complete_keys
    set -l tokens (commandline -xpc)
    if test "$tokens[2]" = --
        set -e tokens[2]
    end
    test (count $tokens) -eq 3; or return 1
    contains -- $tokens[2] get has unset set; or return 1

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
complete -c hmap -n __fish_use_subcommand -a is -d 'Test an hmap'
complete -c hmap -n __fish_use_subcommand -a unset -d 'Remove a key'
complete -c hmap -n __fish_use_subcommand -a assign -d 'Set key-value pairs'
complete -c hmap -n __fish_use_subcommand -a merge -d 'Copy keys from a source'
complete -c hmap -n __fish_use_subcommand -a clear -d 'Remove all keys'
complete -c hmap -n __fish_use_subcommand -a keys -d 'Print keys'
complete -c hmap -n __fish_use_subcommand -a values -d 'Print values'
complete -c hmap -n __fish_use_subcommand -a length -d 'Count keys'

complete -c hmap \
    -k \
    -a '(__hmap_complete_keys)'

source (status dirname)/../functions/hmap.fish

# Force any autoloaded hmap completions to load before clearing them.
complete -C 'hmap ' >/dev/null
complete -c hmap -e
source (status dirname)/../completions/hmap.fish

hmap new foo
hmap assign $foo \
    name Joel \
    user.name dotted \
    "full name" "Joel T" \
    -k dashv

function __hmap_complete_C
    complete -C $argv[1] | string replace -r '\t.*' ''
end

function __case_hmap_complete_verbs
    @echo completions: subcommands
    @test "hmap tab completes subcommands" \
        (__hmap_complete_C 'hmap ' | string collect) = (printf '%s\n' assign clear get has keys length merge new set unset values | string collect)
end

function __case_hmap_complete_maps
    @echo completions: maps
    @test "get does not suggest maps without a variable prefix" \
        (count (__hmap_complete_C 'hmap get ')) -eq 0
end

function __case_hmap_complete_keys
    @echo completions: keys
    @test "get completes keys in insertion order" \
        (__hmap_complete_C 'hmap get $foo ' | string collect) = (printf '%s\n' name user.name "full name" -k | string collect)
    @test "get completes a key prefix" \
        (__hmap_complete_C 'hmap get $foo na') = name
    @test "keys does not complete keys" \
        (count (__hmap_complete_C 'hmap keys $foo ')) -eq 0
    @test "a key named assign does not enable key completion in values" \
        (count (__hmap_complete_C 'hmap set $foo assign value ')) -eq 0
end

function __case_hmap_complete_assign
    @echo completions: assign
    @test "assign does not complete keys" \
        (count (__hmap_complete_C 'hmap assign $foo ')) -eq 0
    @test "assign does not complete values" \
        (count (__hmap_complete_C 'hmap assign $foo name ')) -eq 0
end

__case_hmap_complete_verbs
__case_hmap_complete_maps
__case_hmap_complete_keys
__case_hmap_complete_assign

source (status dirname)/../functions/hmap.fish

# Force any autoloaded hmap completions to load before clearing them.
complete -C 'hmap ' >/dev/null
complete -c hmap -e
source (status dirname)/../completions/hmap.fish

set hmap_root (status dirname)/..

# Completion helpers cannot see hmaps local to test functions, so these
# fixtures live at script scope.
hmap new foo
hmap new src
hmap assign $foo \
    name Joel \
    user.name dotted \
    "full name" "Joel T" \
    -k dashv

function __hmap_complete_C
    complete -C $argv[1] | string replace -r '\t.*' ''
end

# Map $NAMEs are inserted by the Tab bind, not complete -C.
function __hmap_tab_on -a buf
    fish --private --no-config -ic "
        source $hmap_root/functions/hmap.fish
        complete -c hmap -e
        source $hmap_root/completions/hmap.fish
        hmap new foo
        hmap new src
        commandline -r $(string escape -- $buf)
        commandline -C 10000
        __hmap_tab
        commandline -t
    " </dev/null
end

function __case_hmap_complete_verbs
    @echo completions: subcommands
    @test "hmap tab lists subcommands" \
        (__hmap_complete_C 'hmap ' | string collect) = (printf '%s\n' assign clear get has keys length merge new set unset values | string collect)
end

function __case_hmap_complete_maps
    @echo completions: maps
    @test "keys tab inserts a map \$NAME" \
        (__hmap_tab_on 'hmap keys ') = '$foo'
    @test "keys tab cycles map \$NAMEs" \
        (__hmap_tab_on 'hmap keys $foo') = '$src'
    @test "merge tab inserts a map \$NAME" \
        (__hmap_tab_on 'hmap merge ') = '$foo'
    @test "merge tab after a map includes the destination" \
        (__hmap_tab_on 'hmap merge $foo ') = '$foo'
    @test "new tab does not insert a map \$NAME" \
        (__hmap_tab_on 'hmap new ') = ""
end

function __case_hmap_complete_keys
    @echo completions: keys
    @test "get completes keys in insertion order" \
        (__hmap_complete_C 'hmap get $foo ' | string collect) = (printf '%s\n' name user.name "full name" -k | string collect)
    @test "keys does not complete keys" \
        (count (__hmap_complete_C 'hmap keys $foo ')) -eq 0
end

function __case_hmap_complete_assign
    @echo completions: assign
    @test "assign does not complete values" \
        (count (__hmap_complete_C 'hmap assign $foo name ')) -eq 0
    @test "assign completes keys after a pair" \
        (__hmap_complete_C 'hmap assign $foo name Joel ' | string collect) = (__hmap_complete_C 'hmap get $foo ' | string collect)
end

__case_hmap_complete_verbs
__case_hmap_complete_maps
__case_hmap_complete_keys
__case_hmap_complete_assign

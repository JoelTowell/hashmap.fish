source (status dirname)/../functions/hmap.fish

function __hmap_status_test_fails
    return 7
end

function __suite_hmap_set_get
    function __case_hmap_set_get
        hmap new foo
        hmap set $foo bar baz
        hmap set $foo qux quux

        @echo set/get
        @test "get returns the first key's value" \
            (hmap get $foo bar) = "baz"
        @test "get returns the second key's value" \
            (hmap get $foo qux) = "quux"
    end

    function __case_hmap_set_list
        hmap new foo
        hmap set $foo bar baz qux quux

        @echo set/get: list value
        @test "get returns a list value" \
            (hmap get $foo bar | string collect) = (printf '%s\n' baz qux quux | string collect)
    end

    function __case_hmap_get_non_existent
        hmap new foo

        @echo get: missing key
        @test "get missing key returns status 1" \
            (hmap get $foo bar 2>/dev/null) $status = 1
    end

    function __case_hmap_set_get_existing_key
        hmap new foo
        hmap set $foo bar baz
        hmap set $foo bar quux

        @echo set: existing key
        @test "set on an existing key overwrites" \
            (hmap get $foo bar) = "quux"
    end

    function __case_hmap_get_default
        hmap new foo
        hmap set $foo bar baz

        @echo get: default
        @test "get missing key returns the default" \
            (hmap get $foo qux default) = "default"
    end

    function __case_hmap_get_empty_entry
        hmap new foo
        hmap set $foo k
        hmap set $foo e ""

        @echo get: empty entry
        @test "get of a key with no values has status 0" \
            (hmap get $foo k) $status = 0
        @test "get of a key with no values prints nothing" \
            (count (hmap get $foo k)) -eq 0
        @test "get of an empty value has status 0" \
            (hmap get $foo e >/dev/null) $status = 0
        @test "get of an empty value prints one empty string" \
            (count (hmap get $foo e)) -eq 1
    end

    function __case_hmap_set_dash_key
        hmap new foo
        hmap set $foo -k -v

        @echo set/get: dash-prefixed
        @test "get returns a dash-prefixed key" \
            (hmap get $foo -k) = "-v"
    end

    function __case_hmap_set_get_empty_key
        hmap new foo
        hmap set $foo "" empty-key-value

        @echo set/get: empty key
        @test "get returns the value for an empty key" \
            (hmap get $foo "") = "empty-key-value"
        @test "keys includes the empty key" \
            (hmap keys $foo | string collect) = (printf '%s\n' "" | string collect)
    end

    function __case_hmap_escaped_keys
        hmap new foo
        hmap set $foo user.name Joel
        hmap set $foo "a b" spaced

        @echo set/get: dotted and spaced keys
        @test "get returns a dotted key" \
            (hmap get $foo user.name) = "Joel"
        @test "get returns a key with a space" \
            (hmap get $foo "a b") = "spaced"
        @test "keys returns dotted and spaced keys" \
            (hmap keys $foo | string collect) = (printf '%s\n' user.name "a b" | string collect)
    end

    function __case_hmap_set_usage
        hmap new foo

        @echo set: usage
        @test "set without a key returns status 1" \
            (hmap set $foo 2>/dev/null) $status = 1
    end

    function __case_hmap_get_usage
        hmap new foo

        @echo get: usage
        @test "get without a key returns status 1" \
            (hmap get $foo 2>/dev/null) $status = 1
        @test "get with extra arguments returns status 1" \
            (hmap get $foo k default extra 2>/dev/null) $status = 1
        @test "get with an invalid handle returns status 1" \
            (hmap get garbage key 2>/dev/null) $status = 1
    end

    function __case_hmap_set_status
        hmap new foo

        @echo set: status
        __hmap_status_test_fails
        @test "set after a prior failure returns status 0" \
            (hmap set $foo k v) $status = 0
    end

    __case_hmap_set_get
    __case_hmap_set_list
    __case_hmap_get_non_existent
    __case_hmap_set_get_existing_key
    __case_hmap_get_default
    __case_hmap_get_empty_entry
    __case_hmap_set_dash_key
    __case_hmap_set_get_empty_key
    __case_hmap_escaped_keys
    __case_hmap_set_usage
    __case_hmap_get_usage
    __case_hmap_set_status
end

function __suite_hmap_assign
    function __case_hmap_assign
        hmap new foo
        hmap assign $foo \
            bar baz \
            qux quux

        @echo assign
        @test "assign sets the first pair" \
            (hmap get $foo bar) = "baz"
        @test "assign sets the second pair" \
            (hmap get $foo qux) = "quux"
    end

    function __case_hmap_assign_usage
        hmap new foo

        @echo assign: usage
        @test "assign with an odd number of arguments returns status 1" \
            (hmap assign $foo bar 2>/dev/null) $status = 1
        @test "assign with no pairs returns status 0" \
            (hmap assign $foo) $status = 0
    end

    __case_hmap_assign
    __case_hmap_assign_usage
end

function __suite_hmap_merge
    function __case_hmap_merge_no_overlapping_keys
        hmap new foo
        hmap assign $foo \
            bar baz \
            qux quux

        hmap new bar
        hmap assign $bar \
            baz quux

        hmap merge $foo $bar

        @echo merge: no overlapping keys
        @test "merge keeps existing values" \
            (hmap get $foo bar) = "baz"
        @test "merge adds keys from the other hmap" \
            (hmap get $foo baz) = "quux"
        @test "merge appends new keys after existing keys" \
            (hmap keys $foo | string collect) = (printf '%s\n' bar qux baz | string collect)
    end

    function __case_hmap_merge_overlapping_keys
        hmap new foo
        hmap assign $foo \
            bar baz \
            qux quux

        hmap new bar
        hmap assign $bar \
            bar corge \
            grault garply

        hmap merge $foo $bar

        @echo merge: overlapping keys
        @test "merge overrides overlapping values" \
            (hmap get $foo bar) = "corge"
        @test "merge does not duplicate overlapping keys" \
            (hmap keys $foo | string collect) = (printf '%s\n' bar qux grault | string collect)
    end

    function __case_hmap_merge_usage
        hmap new foo
        hmap new bar

        @echo merge: usage
        @test "merge without a source returns status 1" \
            (hmap merge $foo 2>/dev/null) $status = 1
        @test "merge with extra arguments returns status 1" \
            (hmap merge $foo $bar extra 2>/dev/null) $status = 1
        @test "merge with an invalid handle returns status 1" \
            (hmap merge $foo garbage 2>/dev/null) $status = 1
    end

    __case_hmap_merge_no_overlapping_keys
    __case_hmap_merge_overlapping_keys
    __case_hmap_merge_usage
end

function __suite_hmap_keys
    function __case_hmap_keys_empty
        hmap new foo

        @echo keys: empty
        @test "keys is empty on a new hmap" \
            (count (hmap keys $foo)) -eq 0
        @test "keys on an empty hmap returns status 0" \
            (hmap keys $foo) $status = 0
    end

    function __case_hmap_keys_insertion_order
        hmap new foo
        hmap set $foo bar baz
        hmap set $foo qux quux

        @echo keys: insertion order
        @test "keys returns insertion order" \
            (hmap keys $foo | string collect) = (printf '%s\n' bar qux | string collect)
    end

    function __case_hmap_keys_usage
        hmap new foo

        @echo keys: usage
        @test "keys with extra arguments returns status 1" \
            (hmap keys $foo extra 2>/dev/null) $status = 1
    end

    __case_hmap_keys_empty
    __case_hmap_keys_insertion_order
    __case_hmap_keys_usage
end

function __suite_hmap_values
    function __case_hmap_values_empty
        hmap new foo

        @echo values: empty
        @test "values is empty on a new hmap" \
            (count (hmap values $foo)) -eq 0
        @test "values on an empty hmap returns status 0" \
            (hmap values $foo) $status = 0
    end

    function __case_hmap_values_follow_key_order
        hmap new foo
        hmap set $foo bar baz
        hmap set $foo qux quux

        @echo values: key order
        @test "values follow key order" \
            (hmap values $foo | string collect) = (printf '%s\n' baz quux | string collect)
    end

    function __case_hmap_values_flattens_list_entries
        hmap new foo
        hmap set $foo bar baz
        hmap set $foo qux quux corge grault

        @echo values: flatten
        @test "values flattens list entries" \
            (hmap values $foo | string collect) = (printf '%s\n' baz quux corge grault | string collect)
    end

    function __case_hmap_values_usage
        hmap new foo

        @echo values: usage
        @test "values with extra arguments returns status 1" \
            (hmap values $foo extra 2>/dev/null) $status = 1
    end

    __case_hmap_values_empty
    __case_hmap_values_follow_key_order
    __case_hmap_values_flattens_list_entries
    __case_hmap_values_usage
end

function __suite_hmap_unset
    function __case_hmap_unset_middle_key
        hmap new foo
        hmap assign $foo \
            bar baz \
            qux quux \
            corge grault

        hmap unset $foo qux

        @echo unset: middle key
        @test "unset middle key removes it" \
            (hmap get $foo qux 2>/dev/null) $status = 1
        @test "unset middle key keeps the last key" \
            (hmap get $foo corge) = "grault"
        @test "unset middle key closes the hole in keys" \
            (hmap keys $foo | string collect) = (printf '%s\n' bar corge | string collect)
    end

    function __case_hmap_unset_missing_key
        hmap new foo
        hmap set $foo bar baz
        hmap unset $foo qux

        @echo unset: missing key
        @test "unset missing key leaves existing keys" \
            (hmap get $foo bar) = "baz"
    end

    function __case_hmap_unset_usage
        hmap new foo

        @echo unset: usage
        @test "unset without a key returns status 1" \
            (hmap unset $foo 2>/dev/null) $status = 1
        @test "unset with extra arguments returns status 1" \
            (hmap unset $foo k extra 2>/dev/null) $status = 1
    end

    function __case_hmap_unset_status
        hmap new foo
        hmap set $foo k v

        @echo unset: status
        __hmap_status_test_fails
        @test "unset after a prior failure returns status 0" \
            (hmap unset $foo k) $status = 0
    end

    __case_hmap_unset_middle_key
    __case_hmap_unset_missing_key
    __case_hmap_unset_usage
    __case_hmap_unset_status
end

function __suite_hmap_clear
    function __case_hmap_clear
        hmap new foo
        hmap assign $foo \
            bar baz \
            qux quux

        hmap clear $foo

        @echo clear
        @test "clear leaves no keys" \
            (count (hmap keys $foo)) -eq 0
        @test "clear on empty returns status 0" \
            (hmap clear $foo) $status = 0
    end

    function __case_hmap_clear_usage
        hmap new foo

        @echo clear: usage
        @test "clear with extra arguments returns status 1" \
            (hmap clear $foo extra 2>/dev/null) $status = 1
    end

    __case_hmap_clear
    __case_hmap_clear_usage
end

function __suite_hmap_has
    function __case_hmap_has
        hmap new foo
        hmap set $foo bar baz

        @echo has
        @test "has returns true for a present key" \
            (hmap has $foo bar) $status = 0
        @test "has returns false for a missing key" \
            (hmap has $foo qux) $status = 1
    end

    function __case_hmap_has_usage
        hmap new foo

        @echo has: usage
        @test "has without a key returns status 1" \
            (hmap has $foo 2>/dev/null) $status = 1
        @test "has with extra arguments returns status 1" \
            (hmap has $foo k extra 2>/dev/null) $status = 1
    end

    __case_hmap_has
    __case_hmap_has_usage
end

function __suite_hmap_length
    function __case_hmap_length_empty
        hmap new foo

        @echo length: empty
        @test "length is zero when empty" \
            (hmap length $foo) = 0
    end

    function __case_hmap_length_after_set
        hmap new foo
        hmap set $foo bar baz
        hmap set $foo qux quux

        @echo length: after set
        @test "length counts each key" \
            (hmap length $foo) = 2
    end

    function __case_hmap_length_list_value_is_one
        hmap new foo
        hmap set $foo bar baz qux quux

        @echo length: list value
        @test "length counts a list value as one key" \
            (hmap length $foo) = 1
    end

    function __case_hmap_length_usage
        hmap new foo

        @echo length: usage
        @test "length with extra arguments returns status 1" \
            (hmap length $foo extra 2>/dev/null) $status = 1
    end

    __case_hmap_length_empty
    __case_hmap_length_after_set
    __case_hmap_length_list_value_is_one
    __case_hmap_length_usage
end

function __suite_hmap_new
    function __case_hmap_new_handle
        hmap new foo
        hmap new bar

        @echo new: handle
        @test "new stores a handle" \
            (string match -qr '^__hmap_[0-9]+_[0-9]+$' -- $foo) $status = 0
        @test "two hmaps in one scope get different handles" \
            $foo != $bar
    end

    function __case_hmap_new_copied_handle_survives_recreate
        hmap new foo
        hmap set $foo x OLD
        set bar $foo
        set -e foo
        hmap new foo
        hmap set $foo x NEW

        @echo new: copied handle
        @test "copied handle keeps the old hmap" \
            (hmap get $bar x) = "OLD"
        @test "reused name refers to the new hmap" \
            (hmap get $foo x) = "NEW"
    end

    function __case_hmap_new_scope
        function __hmap_new_in_helper
            hmap new foo
        end
        __hmap_new_in_helper

        @echo new: scope
        @test "hmap does not leak from a function" \
            (set -q foo) $status = 1
    end

    function __case_hmap_new_usage
        hmap new foo

        @echo new: usage
        @test "new twice in one scope returns status 1" \
            (hmap new foo 2>/dev/null) $status = 1
        @test "new with an invalid NAME returns status 1" \
            (hmap new "not a name" 2>/dev/null) $status = 1
        @test "new with extra arguments returns status 1" \
            (hmap new baz extra 2>/dev/null) $status = 1
    end

    function __case_hmap_new_reserved_names
        @echo new: reserved names
        @test "new with argv returns status 1" \
            (hmap new argv 2>/dev/null) $status = 1
        @test "new with argv_opts returns status 1" \
            (hmap new argv_opts 2>/dev/null) $status = 1
        @test "new with a __hmap_ prefix returns status 1" \
            (hmap new __hmap_x 2>/dev/null) $status = 1
        @test "new with a _flag_ prefix returns status 1" \
            (hmap new _flag_help 2>/dev/null) $status = 1
    end

    function __case_hmap_new_digit_name
        hmap new 123
        hmap set $123 x 1

        @echo new: digit name
        @test "get works with a digit-only NAME" \
            (hmap get $123 x) = "1"
    end

    function __case_hmap_new_inner_scope
        hmap new foo
        hmap set $foo x OUTER

        function __hmap_inner_foo
            hmap new foo
            hmap set $foo x INNER
        end
        __hmap_inner_foo

        @echo new: inner scope
        @test "inner hmap does not disturb the outer hmap" \
            (hmap get $foo x) = "OUTER"
    end

    function __case_hmap_handle_across_function_boundary
        function __hmap_outer
            hmap new foo
            hmap set $foo x 1
            __hmap_inner $foo
        end

        function __hmap_inner -a handle
            hmap get $handle x
        end

        @echo handle: across functions
        @test "handle does not work in a callee" \
            (__hmap_outer >/dev/null 2>&1) $status = 1
    end

    function __case_hmap_new_status
        @echo new: status
        __hmap_status_test_fails
        @test "new after a prior failure returns status 0" \
            (hmap new baz) $status = 0
    end

    __case_hmap_new_handle
    __case_hmap_new_copied_handle_survives_recreate
    __case_hmap_new_scope
    __case_hmap_new_usage
    __case_hmap_new_reserved_names
    __case_hmap_new_digit_name
    __case_hmap_new_inner_scope
    __case_hmap_handle_across_function_boundary
    __case_hmap_new_status
end

function __suite_hmap_dispatch
    function __case_hmap_help
        @echo dispatch: help
        @test "hmap --help returns status 0" \
            (hmap --help >/dev/null) $status = 0
        @test "hmap with no arguments returns status 0" \
            (hmap >/dev/null) $status = 0
    end

    function __case_hmap_unknown_operation
        @echo dispatch: unknown operation
        @test "unknown operation returns status 1" \
            (hmap nope 2>/dev/null) $status = 1
    end

    __case_hmap_help
    __case_hmap_unknown_operation
end

__suite_hmap_set_get
__suite_hmap_assign
__suite_hmap_merge
__suite_hmap_keys
__suite_hmap_values
__suite_hmap_unset
__suite_hmap_clear
__suite_hmap_has
__suite_hmap_length
__suite_hmap_new
__suite_hmap_dispatch

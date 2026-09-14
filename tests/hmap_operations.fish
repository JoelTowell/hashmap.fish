source (status dirname)/../functions/hmap.fish

function __suite_hmap_set_get
    function __case_hmap_set_get
        hmap new foo
        foo set bar baz

        @echo set/get
        @test "get returns the value" \
            (foo get bar) = "baz"
    end

    function __case_hmap_set_get_multiple
        hmap new foo
        foo set bar baz
        foo set qux quux

        @echo set/get: multiple keys
        @test "get returns the first key's value" \
            (foo get bar) = "baz"
        @test "get returns the second key's value" \
            (foo get qux) = "quux"
    end

    function __case_hmap_set_list
        hmap new foo
        foo set bar baz qux quux

        @echo set/get: list value
        @test "get returns a list value" \
            (foo get bar | string collect) = (printf '%s\n' baz qux quux | string collect)
    end

    function __case_hmap_get_non_existent
        hmap new foo

        @echo get: missing key
        @test "get missing key returns status 1" \
            (foo get bar 2>/dev/null) $status = 1
    end

    function __case_hmap_set_get_existing_key
        hmap new foo
        foo set bar baz
        foo set bar quux

        @echo set: existing key
        @test "set on an existing key overwrites" \
            (foo get bar) = "quux"
    end

    function __case_hmap_set_get_non_existent_key_with_default
        hmap new foo
        foo set bar baz

        @echo get: default
        @test "get missing key returns the default" \
            (foo get qux default) = "default"
    end

    function __case_hmap_set_usage
        hmap new foo

        @echo set: usage
        @test "set without a key returns status 1" \
            (foo set 2>/dev/null) $status = 1
        @test "set with an empty key returns status 1" \
            (foo set "" bar 2>/dev/null) $status = 1
    end

    function __case_hmap_get_usage
        hmap new foo

        @echo get: usage
        @test "get without a key returns status 1" \
            (foo get 2>/dev/null) $status = 1
        @test "get with an empty key returns status 1" \
            (foo get "" 2>/dev/null) $status = 1
    end

    function __case_hmap_unknown_operation
        hmap new foo

        @echo dispatch: unknown operation
        @test "unknown operation returns status 1" \
            (foo nope 2>/dev/null) $status = 1
    end

    __case_hmap_set_get
    __case_hmap_set_get_multiple
    __case_hmap_set_list
    __case_hmap_get_non_existent
    __case_hmap_set_get_existing_key
    __case_hmap_set_get_non_existent_key_with_default
    __case_hmap_set_usage
    __case_hmap_get_usage
    __case_hmap_unknown_operation
end

function __suite_hmap_assign
    function __case_hmap_assign
        hmap new foo
        foo assign \
            bar baz \
            qux quux


        @echo assign
        @test "assign sets the first pair" \
            (foo get bar) = "baz"
        @test "assign sets the second pair" \
            (foo get qux) = "quux"
    end

    function __case_hmap_assign_usage
        hmap new foo

        @echo assign: usage
        @test "assign with an odd number of arguments returns status 1" \
            (foo assign bar 2>/dev/null) $status = 1
    end

    __case_hmap_assign
    __case_hmap_assign_usage
end

function __suite_hmap_merge
    function __case_hmap_merge_no_overlapping_keys
        hmap new foo
        foo assign \
            bar baz \
            qux quux

        hmap new bar
        bar assign \
            baz quux

        foo merge bar

        @echo merge: no overlapping keys
        @test "merge keeps the first existing value" \
            (foo get bar) = "baz"
        @test "merge keeps the second existing value" \
            (foo get qux) = "quux"
        @test "merge adds keys from the other map" \
            (foo get baz) = "quux"
        @test "merge appends new keys after existing keys" \
            (foo keys | string collect) = (printf '%s\n' bar qux baz | string collect)
    end

    function __case_hmap_merge_overlapping_keys
        hmap new foo
        foo assign \
            bar baz \
            qux quux

        hmap new bar
        bar assign \
            bar corge \
            grault garply

        foo merge bar

        @echo merge: overlapping keys
        @test "merge overrides overlapping values" \
            (foo get bar) = "corge"
        @test "merge keeps non-overlapping values" \
            (foo get qux) = "quux"
        @test "merge adds non-overlapping keys from the other map" \
            (foo get grault) = "garply"
        @test "merge does not duplicate overlapping keys" \
            (foo keys | string collect) = (printf '%s\n' bar qux grault | string collect)
    end

    function __case_hmap_merge_usage
        hmap new foo

        @echo merge: usage
        @test "merge without a name returns status 1" \
            (foo merge 2>/dev/null) $status = 1
        @test "merge of a missing command returns status 1" \
            (foo merge nosuch 2>/dev/null) $status = 1

        function not_an_hmap
        end
        @test "merge of a non-hmap function returns status 1" \
            (foo merge not_an_hmap 2>/dev/null) $status = 1
        functions -e not_an_hmap
    end

    __case_hmap_merge_no_overlapping_keys
    __case_hmap_merge_overlapping_keys
    __case_hmap_merge_usage
end

function __suite_hmap_keys
    function __case_hmap_keys_empty
        hmap new foo
        @echo keys: empty
        @test "keys is empty on a new map" \
            (count (foo keys)) -eq 0
    end

    function __case_hmap_keys_single
        hmap new foo
        foo set bar baz
        @echo keys: single
        @test "keys returns the single key" \
            (foo keys) = "bar"
    end

    function __case_hmap_keys_insertion_order
        hmap new foo
        foo set bar baz
        foo set qux quux
        @echo keys: insertion order
        @test "keys returns insertion order" \
            (foo keys | string collect) = (printf '%s\n' bar qux | string collect)
    end

    function __case_hmap_keys_list_value_is_one_key
        hmap new foo
        foo set bar baz qux quux
        @echo keys: list value
        @test "keys counts a list value as one key" \
            (foo keys) = "bar"
    end

    __case_hmap_keys_empty
    __case_hmap_keys_single
    __case_hmap_keys_insertion_order
    __case_hmap_keys_list_value_is_one_key
end

function __suite_hmap_values
    function __case_hmap_values_empty
        hmap new foo
        @echo values: empty
        @test "values is empty on a new map" \
            (count (foo values)) -eq 0
    end

    function __case_hmap_values_single
        hmap new foo
        foo set bar baz
        @echo values: single
        @test "values returns the single value" \
            (foo values) = "baz"
    end

    function __case_hmap_values_follow_key_order
        hmap new foo
        foo set bar baz
        foo set qux quux
        @echo values: key order
        @test "values follow key order" \
            (foo values | string collect) = (printf '%s\n' baz quux | string collect)
    end

    function __case_hmap_values_flattens_list_entries
        hmap new foo
        foo set bar baz
        foo set qux quux corge grault
        @echo values: flatten
        @test "values flattens list entries" \
            (foo values | string collect) = (printf '%s\n' baz quux corge grault | string collect)
    end

    __case_hmap_values_empty
    __case_hmap_values_single
    __case_hmap_values_follow_key_order
    __case_hmap_values_flattens_list_entries
end

function __suite_hmap_unset
    function __case_hmap_unset
        hmap new foo
        foo set bar baz
        foo unset bar

        @echo unset
        @test "unset removes the value" \
            (foo get bar 2>/dev/null) $status = 1
    end

    function __case_hmap_unset_middle_key
        hmap new foo
        foo assign \
            bar baz \
            qux quux \
            corge grault

        foo unset qux

        @echo unset: middle key
        @test "unset middle key removes it" \
            (foo get qux 2>/dev/null) $status = 1
        @test "unset middle key keeps the first key" \
            (foo get bar) = "baz"
        @test "unset middle key keeps the last key" \
            (foo get corge) = "grault"
        @test "unset middle key closes the hole in keys" \
            (foo keys | string collect) = (printf '%s\n' bar corge | string collect)
    end

    function __case_hmap_unset_missing_key
        hmap new foo
        foo set bar baz
        foo unset qux

        @echo unset: missing key
        @test "unset missing key leaves existing keys" \
            (foo get bar) = "baz"
    end

    function __case_hmap_set_after_unset
        hmap new foo
        foo set bar baz
        foo unset bar
        foo set bar quux

        @echo set after unset
        @test "set after unset stores the new value" \
            (foo get bar) = "quux"
    end

    function __case_hmap_unset_usage
        hmap new foo

        @echo unset: usage
        @test "unset without a key returns status 1" \
            (foo unset 2>/dev/null) $status = 1
        @test "unset with an empty key returns status 1" \
            (foo unset "" 2>/dev/null) $status = 1
    end

    __case_hmap_unset
    __case_hmap_unset_middle_key
    __case_hmap_unset_missing_key
    __case_hmap_set_after_unset
    __case_hmap_unset_usage
end

function __suite_hmap_clear
    function __case_hmap_clear
        hmap new foo
        foo assign \
            bar baz \
            qux quux

        foo clear

        @echo clear
        @test "clear removes the first key" \
            (foo get bar 2>/dev/null) $status = 1
        @test "clear removes the second key" \
            (foo get qux 2>/dev/null) $status = 1
        @test "clear leaves no keys" \
            (count (foo keys)) -eq 0
    end

    function __case_hmap_clear_empty
        hmap new foo
        foo clear

        @echo clear: empty
        @test "clear on empty leaves the map empty" \
            (count (foo keys)) -eq 0
    end

    __case_hmap_clear
    __case_hmap_clear_empty
end

function __suite_hmap_has
    function __case_hmap_has_empty
        hmap new foo

        @echo has: empty
        @test "has on empty map is false" \
            (foo has bar) $status = 1
    end

    function __case_hmap_has_present
        hmap new foo
        foo set bar baz

        @echo has: present
        @test "has returns true for a present key" \
            (foo has bar) $status = 0
    end

    function __case_hmap_has_absent
        hmap new foo
        foo set bar baz

        @echo has: absent
        @test "has returns false for a missing key" \
            (foo has qux) $status = 1
    end

    function __case_hmap_has_after_unset
        hmap new foo
        foo set bar baz
        foo unset bar

        @echo has: after unset
        @test "has returns false after unset" \
            (foo has bar) $status = 1
    end

    function __case_hmap_has_usage
        hmap new foo

        @echo has: usage
        @test "has without a key returns status 1" \
            (foo has 2>/dev/null) $status = 1
        @test "has with an empty key returns status 1" \
            (foo has "" 2>/dev/null) $status = 1
    end

    __case_hmap_has_empty
    __case_hmap_has_present
    __case_hmap_has_absent
    __case_hmap_has_after_unset
    __case_hmap_has_usage
end

function __suite_hmap_length
    function __case_hmap_length_empty
        hmap new foo

        @echo length: empty
        @test "length is zero when empty" \
            (foo length) = 0
    end

    function __case_hmap_length_after_set
        hmap new foo
        foo set bar baz
        foo set qux quux

        @echo length: after set
        @test "length counts each key" \
            (foo length) = 2
    end

    function __case_hmap_length_list_value_is_one
        hmap new foo
        foo set bar baz qux quux

        @echo length: list value
        @test "length counts a list value as one key" \
            (foo length) = 1
    end

    function __case_hmap_length_after_unset
        hmap new foo
        foo set bar baz
        foo set qux quux
        foo unset bar

        @echo length: after unset
        @test "length decreases after unset" \
            (foo length) = 1
    end

    function __case_hmap_length_after_clear
        hmap new foo
        foo set bar baz
        foo clear

        @echo length: after clear
        @test "length is zero after clear" \
            (foo length) = 0
    end

    __case_hmap_length_empty
    __case_hmap_length_after_set
    __case_hmap_length_list_value_is_one
    __case_hmap_length_after_unset
    __case_hmap_length_after_clear
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

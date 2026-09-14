source (status dirname)/../functions/hmap.fish

function __suite_hmap_set_get
    function __case_hmap_set_get
        hmap new foo
        foo set bar baz

        @test "it returns the correct value for the key" (foo get bar) = "baz"
    end

    function __case_hmap_set_get_multiple
        hmap new foo
        foo set bar baz
        foo set qux quux

        @test "it returns the correct value for the key bar" (foo get bar) = "baz"
        @test "it returns the correct value for the key qux" (foo get qux) = "quux"
    end

    function __case_hmap_set_list
        hmap new foo
        foo set bar baz qux quux

        @test "it returns the list for the key" (foo get bar | string collect) = (printf '%s\n' baz qux quux | string collect)
    end

    function __case_hmap_get_non_existent
        hmap new foo

        @test "it returns an error when getting a non-existent key" (foo get bar 2>/dev/null) $status = 1
    end

    function __case_hmap_set_get_existing_key
        hmap new foo
        foo set bar baz
        foo set bar quux

        @test "it returns the new value" (foo get bar) = "quux"
    end

    __case_hmap_set_get
    __case_hmap_set_get_multiple
    __case_hmap_set_list
    __case_hmap_get_non_existent
    __case_hmap_set_get_existing_key
end

function __suite_hmap_assign
    function __case_hmap_assign
        hmap new foo
        foo assign \
            bar baz \
            qux quux


        @test "it returns the correct value for the key bar" (foo get bar) = "baz" 
        @test "it returns the correct value for the key qux" (foo get qux) = "quux"
    end

    __case_hmap_assign
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

        @test "it keeps the first existing value" (foo get bar) = "baz"
        @test "it keeps the second existing value" (foo get qux) = "quux"
        @test "it adds values from the other hmap" (foo get baz) = "quux"
        @test "it appends new keys after existing keys" (foo keys | string collect) = (printf '%s\n' bar qux baz | string collect)
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

        @test "it overrides existing values" (foo get bar) = "corge"
        @test "it keeps values for keys that do not overlap" (foo get qux) = "quux"
        @test "it adds values from the other hmap" (foo get grault) = "garply"
        @test "it does not duplicate overlapping keys" (foo keys | string collect) = (printf '%s\n' bar qux grault | string collect)
    end

    __case_hmap_merge_no_overlapping_keys
    __case_hmap_merge_overlapping_keys
end

function __suite_hmap_keys
    function __case_hmap_keys_empty
        hmap new foo
        @test "it returns no keys" (count (foo keys)) -eq 0
    end

    function __case_hmap_keys_single
        hmap new foo
        foo set bar baz
        @test "it returns the key" (foo keys) = "bar"
    end

    function __case_hmap_keys_insertion_order
        hmap new foo
        foo set bar baz
        foo set qux quux
        @test "it returns keys in insertion order" (foo keys | string collect) = (printf '%s\n' bar qux | string collect)
    end

    function __case_hmap_keys_list_value_is_one_key
        hmap new foo
        foo set bar baz qux quux
        @test "it registers a single key for a list value" (foo keys) = "bar"
    end

    __case_hmap_keys_empty
    __case_hmap_keys_single
    __case_hmap_keys_insertion_order
    __case_hmap_keys_list_value_is_one_key
end

function __suite_hmap_values
    function __case_hmap_values_empty
        hmap new foo
        @test "it returns no values" (count (foo values)) -eq 0
    end

    function __case_hmap_values_single
        hmap new foo
        foo set bar baz
        @test "it returns the value" (foo values) = "baz"
    end

    function __case_hmap_values_follow_key_order
        hmap new foo
        foo set bar baz
        foo set qux quux
        @test "it returns values in key order" (foo values | string collect) = (printf '%s\n' baz quux | string collect)
    end

    function __case_hmap_values_flattens_list_entries
        hmap new foo
        foo set bar baz
        foo set qux quux corge grault
        @test "it flattens list values" (foo values | string collect) = (printf '%s\n' baz quux corge grault | string collect)
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

        @test "it removes the value" (foo get bar 2>/dev/null) $status = 1
    end

    function __case_hmap_unset_middle_key
        hmap new foo
        foo assign \
            bar baz \
            qux quux \
            corge grault

        foo unset qux

        @test "it removes the value" (foo get qux 2>/dev/null) $status = 1
        @test "it keeps the first key" (foo get bar) = "baz"
        @test "it keeps the last key" (foo get corge) = "grault"
        @test "it closes the hole in the keys list" (foo keys | string collect) = (printf '%s\n' bar corge | string collect)
    end

    function __case_hmap_unset_missing_key
        hmap new foo
        foo set bar baz
        foo unset qux

        @test "it leaves existing keys alone" (foo get bar) = "baz"
    end

    function __case_hmap_set_after_unset
        hmap new foo
        foo set bar baz
        foo unset bar
        foo set bar quux

        @test "it returns the new value" (foo get bar) = "quux"
    end

    __case_hmap_unset
    __case_hmap_unset_middle_key
    __case_hmap_unset_missing_key
    __case_hmap_set_after_unset
end

function __suite_hmap_clear
    function __case_hmap_clear
        hmap new foo
        foo assign \
            bar baz \
            qux quux

        foo clear

        @test "it removes the first key" (foo get bar 2>/dev/null) $status = 1
        @test "it removes the second key" (foo get qux 2>/dev/null) $status = 1
        @test "it leaves no keys" (count (foo keys)) -eq 0
    end

    function __case_hmap_clear_empty
        hmap new foo
        foo clear

        @test "it leaves the map empty" (count (foo keys)) -eq 0
    end

    __case_hmap_clear
    __case_hmap_clear_empty
end

function __suite_hmap_has
    function __case_hmap_has_empty
        hmap new foo

        @test "it does not have a key" (foo has bar) $status = 1
    end

    function __case_hmap_has_present
        hmap new foo
        foo set bar baz

        @test "it has the key" (foo has bar) $status = 0
    end

    function __case_hmap_has_absent
        hmap new foo
        foo set bar baz

        @test "it does not have a different key" (foo has qux) $status = 1
    end

    function __case_hmap_has_after_unset
        hmap new foo
        foo set bar baz
        foo unset bar

        @test "it does not have an unset key" (foo has bar) $status = 1
    end

    __case_hmap_has_empty
    __case_hmap_has_present
    __case_hmap_has_absent
    __case_hmap_has_after_unset
end

function __suite_hmap_length
    function __case_hmap_length_empty
        hmap new foo

        @test "it is zero when empty" (foo length) = 0
    end

    function __case_hmap_length_after_set
        hmap new foo
        foo set bar baz
        foo set qux quux

        @test "it counts each key" (foo length) = 2
    end

    function __case_hmap_length_list_value_is_one
        hmap new foo
        foo set bar baz qux quux

        @test "it counts a list value as one key" (foo length) = 1
    end

    function __case_hmap_length_after_unset
        hmap new foo
        foo set bar baz
        foo set qux quux
        foo unset bar

        @test "it decreases after unset" (foo length) = 1
    end

    function __case_hmap_length_after_clear
        hmap new foo
        foo set bar baz
        foo clear

        @test "it is zero after clear" (foo length) = 0
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
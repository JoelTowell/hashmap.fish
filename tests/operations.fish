source (status dirname)/../functions/hmap.fish

function __case_set_get
    hmap new foo
    foo set bar baz

    @test "it sets the correct value" (foo values) = "baz"
    @test "it registers the key in the keys list" (foo keys) = "bar"
    @test "it returns the correct value when getting a key" (foo get bar) = "baz"
    @test "it returns an error when getting a non-existent key" (foo get baz 2>/dev/null) $status = 1
end

function __case_set_get_multiple
    hmap new foo
    foo set bar baz
    foo set qux quux

    @test "it sets the correct values" (foo values | string collect) = (printf '%s\n' baz quux | string collect)
    @test "it registers the keys in the keys list" (foo keys | string collect) = (printf '%s\n' bar qux | string collect)
    @test "it returns the correct value when getting a key" (foo get bar) = "baz"
    @test "it returns the correct value when getting a key" (foo get qux) = "quux"
    @test "it returns an error when getting a non-existent key" (foo get baz 2>/dev/null) $status -eq 1
end

__case_set_get
__case_set_get_multiple
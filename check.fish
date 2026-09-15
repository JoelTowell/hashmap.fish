#!/usr/bin/env fish

cd (status dirname)

fishtape tests/*.fish
or return

fish_indent --check completions/*.fish functions/*.fish tests/*.fish
or begin
    echo indent failed >&2
    return 1
end
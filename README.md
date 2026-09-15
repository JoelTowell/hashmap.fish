# hmap

Hash maps for Fish, aiming to feel as close to a first-class Fish data structure as reasonably possible.

```fish
hmap new foo
hmap set $foo name Sam
hmap get $foo name
# Sam
```

## Motivation

Fish does not have a native associative-array / hash-map type. You can fake one with a paired list, or keep two arrays in sync, and for a lot of scripts that is enough.

I wanted something that behaves a little more like a normal mutable data structure: held in a variable, with list-valued entries, shared references, and a lifetime that follows Fish scope.

## Requirements

**Fish 4 or later.**

## Installation

The intended path is [Fisher](https://github.com/jorgebucaran/fisher). That is not set up yet, so this does not currently work:

```fish
fisher install JoelTowell/hashmap.fish
```

Clone the repository if you want to try it.

## Usage

A small map of options:

```fish
hmap new opts
hmap assign $opts \
    host localhost \
    port 8080
hmap set $opts tags api internal

hmap get $opts host
# localhost

hmap get $opts timeout 30
# 30

if hmap has $opts port
    hmap get $opts port
end
```

```fish
hmap new foo
hmap set $foo name Sam
```

`new` takes a variable name because it creates the variable. The other commands take `$foo`, the value referring to the map. `hmap set foo ...` passes the literal string `foo`, which is not a map.

```fish
hmap new NAME

hmap set MAP KEY [VALUE...]
hmap get MAP KEY [DEFAULT]
hmap has MAP KEY
hmap unset MAP KEY

hmap assign MAP [KEY VALUE ...]
hmap merge DESTINATION SOURCE
hmap clear MAP

hmap keys MAP
hmap values MAP
hmap length MAP
```

`set` accepts zero, one, or several values.

`get` prints each item on its own line. A missing key is status `1`. Pass a default and it is used only when the key is missing.

`has` is for control flow: status `0` if the key is present, `1` if it is not. A key with no values is still present, so `has` succeeds and `get` does not fall back to the default.

`assign` takes scalar `KEY VALUE` pairs.

`merge` overlays one map onto another.

`clear` removes every key.

For iteration, loop over `keys`. `length` counts keys, not values. `values` prints every value in key order and flattens list-valued entries, so it is a dump rather than a round-trip:

```fish
for key in (hmap keys $opts)
    echo $key
end

hmap length $opts
# 3
```

## Properties

### Reference semantics

Assigning `$foo` to another variable does not copy the contents. Both names refer to the same mutable map:

```fish
set bar $foo
hmap set $bar y 2
hmap get $foo y
# 2
```

### List-valued entries

A key can hold several Fish values, including none, and including a single empty string:

```fish
hmap set $foo colours red green blue
hmap get $foo colours
# red
# green
# blue

hmap set $foo none
hmap set $foo blank ""
```

`colours` has three values. `none` is present and prints nothing. `blank` is present and prints one empty string. A key you never set is missing: `get` is status `1`, `has` is status `1`. `get` with a default does not kick in for `none` or `blank`, because those keys exist.

### Scoped lifetime

A local hmap disappears with its Fish scope. An inner variable of the same name does not replace an outer map.

```fish
function demo
    hmap new foo
    hmap set $foo x 1
end

demo
# $foo is not set; the map is gone
```

### Ordering

Keys keep insertion order. Updating a key leaves it in place. Remove it and set it again, and it is appended.

```fish
hmap assign $foo \
    a 1 \
    b 2 \
    c 3
hmap set $foo a 9
hmap keys $foo
# a
# b
# c

hmap unset $foo a
hmap set $foo a 4
hmap keys $foo
# b
# c
# a
```

## Limitations

A map created locally inside one function cannot currently just be passed to another ordinary function and used there. That is a Fish scoping issue:

```fish
function inner -a map
    hmap get $map x
end

function outer
    hmap new foo
    hmap set $foo x 1
    inner $foo
end

outer
# fails
```

Assigning `$foo` to another variable in the same scope is fine. The limitation is caller-local maps crossing into another function.

## Inspiration and alternatives

[`mattmc3/dict.fish`](https://github.com/mattmc3/dict.fish) is the project that kicked this off. It showed that dictionary-like behaviour in Fish could be both simple and useful, with a deliberately small paired-list approach.

`hmap` is a different trade-off, not a replacement, for people who want list-valued entries, shared mutable references, and scoped map behaviour. If the paired-list approach is what you need, use [dict.fish](https://github.com/mattmc3/dict.fish).

## Contributing

Clone the repository, make the change, run `./check.fish`, and open a pull request.

# hmap

Hash maps for Fish, aiming to feel as close to a first-class Fish data structure as reasonably possible.

```fish
hmap new foo
hmap set $foo name Ada
hmap get $foo name
# Ada
```

## Motivation

Fish does not have a native associative-array / hash-map type. You can fake one with a paired list, or keep two arrays in sync, and for a lot of scripts that is enough.

I wanted something that behaves a little more like a normal mutable data structure: held in a variable, with list-valued entries, shared references, and a lifetime that follows Fish scope.

## Requirements

**Fish 4 or later.**

## Installation

The intended path is [Fisher](https://github.com/jorgebucaran/fisher), but that is not set up yet:

```fish
fisher install JoelTowell/hashmap.fish
```

For now, clone the repository to try it.

## Usage

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

`new` takes a variable name because it creates the variable. Other commands take `$opts`, the value referring to the map. `hmap set opts ...` passes the literal string `opts`, which is not a map.

```fish
hmap new NAME

hmap set MAP KEY [VALUE...]
hmap get MAP KEY [DEFAULT]
hmap has MAP KEY
hmap is MAP
hmap unset MAP KEY

hmap assign MAP [KEY VALUE ...]
hmap merge DESTINATION SOURCE
hmap clear MAP

hmap keys MAP
hmap values MAP
hmap length MAP
```

`set` accepts zero, one, or several values.

`get` returns status `1` for a missing key; an optional default is used only when the key is missing.

`has` returns status `0` when the key exists and `1` otherwise.

`is` is the same check for whether a value is an hmap.

`unset` removes a key.

`assign` takes scalar `KEY VALUE` pairs.

`merge` overlays one map onto another.

`clear` removes every key.

For iteration, loop over `keys`. `length` counts keys, not values. `values` prints values in key order and flattens list-valued entries, so it is not a round-trip representation:

```fish
for key in (hmap keys $opts)
    echo $key
end
```

## Properties

### Reference semantics

Assigning an hmap to another variable does not copy its contents. Both variables refer to the same mutable map:

```fish
set bar $foo
hmap set $bar y 2

hmap get $foo y
# 2
```

### List-valued entries

A key can hold several Fish values:

```fish
hmap set $foo colours red green blue
```

`set` with no values still creates the key. `set KEY ""` stores one empty string. A key that was never set is missing, which is what makes `get`'s default fire.

### Scoped lifetime

A local hmap disappears with its Fish scope:

```fish
function demo
    hmap new foo
    hmap set $foo x 1
end

demo
# $foo is not set; the map is gone
```

### Ordering

Keys keep insertion order. Updating a key leaves it in place; removing and recreating it appends it.

```fish
hmap assign $foo \
    a 1 \
    b 2 \
    c 3

hmap set $foo a 9

hmap unset $foo a
hmap set $foo a 4

hmap keys $foo
# b
# c
# a
```

## Limitations

A map created locally inside one function cannot currently be passed to another ordinary function and used there:

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

This is a consequence of Fish scoping. Assigning the map to another variable in the same scope works normally.

## Inspiration and alternatives

[`mattmc3/dict.fish`](https://github.com/mattmc3/dict.fish) is the project that kicked this off. It showed that dictionary-like behaviour in Fish can be both simple and useful with a deliberately small paired-list approach.

`hmap` explores a different trade-off for list-valued entries, shared mutable references, and scoped map behaviour. If the paired-list approach better fits what you need, check out [dict.fish](https://github.com/mattmc3/dict.fish).

## Contributing

Clone the repository, make the change, run `./check.fish`, and open a pull request.

# hmap

Hash maps for Fish with list-valued entries, shared mutable references, insertion ordering, and a lifetime that follows Fish scope.

## Motivation

Fish has no native associative-array / hash-map type. Paired lists are enough for many simpler cases. `hmap` is for when richer map-like semantics are useful.

## Requirements

**Fish 4 or later.**

## Installation

Install with [Fisher](https://github.com/jorgebucaran/fisher):

```fish
fisher install JoelTowell/hashmap.fish
```

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

`hmap new NAME` takes a variable name because it creates the variable. Other commands take the map reference stored in that variable:

```fish
hmap new opts
hmap set $opts name Ada
```

is correct, while:

```fish
hmap set opts name Ada
```

passes the literal string `opts` rather than the map.

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

`get` returns status `1` for a missing key. An optional default is used only when the key is missing.

`has` returns status `0` when the key exists and `1` otherwise.

`is` returns status `0` if its argument refers to an hmap and `1` otherwise.

`assign` takes scalar `KEY VALUE` pairs.

`length` counts keys.

`values` flattens list-valued entries, so it is not a round-trip representation.

```fish
for key in (hmap keys $opts)
    echo $key
end
```

## Properties

### List-valued entries

A key can hold several Fish values:

```fish
hmap set $foo colours red green blue
```

`set` with no values still creates the key. `set KEY ""` stores one empty string. A key that has never been set is missing; that is when `get`'s default applies.

### Reference semantics

Assigning an hmap reference to another variable does not copy the map. Both variables refer to the same mutable map:

```fish
set bar $foo
hmap set $bar y 2

hmap get $foo y
# 2
```

### Scoped lifetime

A local hmap disappears when its Fish scope ends:

```fish
function demo
    hmap new foo
    hmap set $foo x 1
end

demo
# $foo is not set; the map is gone
```

### Ordering

Keys keep insertion order. Updating an existing key leaves it in place; removing and recreating a key appends it to the end.

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

[`mattmc3/dict.fish`](https://github.com/mattmc3/dict.fish) influenced `hmap`. Its paired-list approach is a simple way to represent dictionaries in Fish and works well for many small scripts.

`hmap` takes a different approach, with list-valued entries, shared references, scoped lifetime, insertion ordering, and a more map-oriented API. If the simpler paired-list approach better fits your needs, `dict.fish` is worth checking out.

## Contributing

Clone the repository, make the change, run `./check.fish`, and open a pull request.

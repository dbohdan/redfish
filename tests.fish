#! /usr/bin/env fish
# redfish: use Redis as a key-value store from fish.
# Copyright (c) 2023 D. Bohdan. License: MIT.

cd "$(path dirname "$(status filename)")"
source redfish.fish

begin
    set --local initial foo1\nfoo2 bar βαζ
    set --local key fish-redis-test
    redfish-write-list $key $initial
    set --local got
    redfish-read-list got $key
    if not test "$initial" = "$got"
        printf '|%s| != |%s|\n' "$initial" "$got"
        return 1
    end

    redfish-write-list $key uno
    redfish-read-list got $key
    test (count $got) -eq 1
    or return 2

    redfish-write-list $key
    redfish-read-list got $key
    test (count $got) -eq 0
    or return 3

    set got "$(redfish-read $key)"
    test "$got" = ''
    or return 4

    redfish-write $key "$foo"
    set got "$(redfish-read $key)"
    test "$got" = "$foo"
    or return 5
end

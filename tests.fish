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
        return 101
    end

    redfish-write-list $key uno
    redfish-read-list got $key
    test (count $got) -eq 1
    or return 102

    redfish-write-list $key
    redfish-read-list got $key
    test (count $got) -eq 0
    or return 103

    set got "$(redfish-read $key)"
    test "$got" = ''
    or return 104

    redfish-write $key "$foo"
    set got "$(redfish-read $key)"
    test "$got" = "$foo"
    or return 105

    redfish-exists $key
    or return 106

    redfish-delete $key
    or return 107

    redfish-delete $key
    and return 108

    redfish-exists $key
    and return 109

    return 0
end

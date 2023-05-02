#! /usr/bin/env fish
# redfish: use Redis as a key-value store from fish.
# Copyright (c) 2023 D. Bohdan. License: MIT.

cd "$(path dirname "$(status filename)")"
source redfish.fish

begin
    set --local initial foo1\nfoo2 bar βαζ
    set --local key redfish:tests:k1
    redfish set-list $key $initial
    set --local got
    redfish get-list got $key
    if not test "$initial" = "$got"
        printf '|%s| != |%s|\n' "$initial" "$got"
        return 101
    end

    redfish set-list $key uno
    redfish get-list got $key
    test (count $got) -eq 1
    or return 102

    redfish set-list $key
    redfish get-list got $key
    test (count $got) -eq 0
    or return 103

    set got "$(redfish get $key)"
    test "$got" = ''
    or return 104

    redfish set $key "$foo"
    set got "$(redfish get $key)"
    test "$got" = "$foo"
    or return 105

    redfish exists $key
    or return 106

    redfish del $key
    or return 107

    redfish del $key
    and return 108

    redfish exists $key
    and return 109

    redfish incr $key
    redfish incr $key
    redfish incr $key 3
    redfish incr $key -2
    test (redfish get $key) -eq 3
    or return 110

    test (redfish keys $key) = $key
    or return 111

    redfish set $key:a x
    redfish set $key:b y
    test "$(redfish del --verbose $key:a $key:b)" -eq 2
    or return 112


    return 0
end

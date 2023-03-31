#! /usr/bin/env fish

function redfish-write --argument-names key
    set --local argc (count $argv)
    if test $argc -eq 0
        return 1
    end

    redis-cli del $key >/dev/null
    if test $argc -eq 1
        return
    end

    set --local rpushed (redis-cli rpush $key (string escape $argv[2..]))
    test "$rpushed" -eq (count $argv[2..])
end

function redfish-read --no-scope-shadowing --argument-names __redfish_var __redfish_key
    if test (count $argv) -ne 2
        return 1
    end

    set $__redfish_var
    if test "$(redis-cli llen $__redfish_key)" -eq 0
        return
    end

    # Do not unescape the results as a whole to prevent values from
    # being split on newlines.
    for __redfish_value in (redis-cli lrange $__redfish_key 0 -1)
        set --append $__redfish_var "$(string unescape $__redfish_value)"
    end

    set --erase __redfish_key __redfish_value __redfish_var
end

function redfish-run-tests
    set --local initial foo1\nfoo2 bar βαζ
    set --local key fish-redfish-test
    redfish-write $key $initial
    set --local got
    redfish-read got $key
    test "$initial" = "$got" || return 1

    redfish-write $key uno
    redfish-read got $key
    test (count $got) -eq 1 || return 1

    redfish-write $key
    redfish-read got $key
    test (count $got) -eq 0 || return 1
end

redfish-run-tests

#! /usr/bin/env fish
# redfish: use Redis as a key-value store from fish.
# Copyright (c) 2023 D. Bohdan. License: MIT.
# Requirements: redis-cli(1), a Redis server (local by default).

if not set --query _redfish_redis_cli_args
    set --global _redfish_redis_cli_args
end

function redfish-redis
    redis-cli $_redfish_redis_cli_args $argv
end

function redfish-write --argument-names key
    set --local argc (count $argv)
    if test $argc -eq 0
        return 1
    end

    redfish-redis del $key >/dev/null
    if test $argc -eq 1
        return
    end

    set --local rpushed (redfish-redis rpush $key (string escape $argv[2..]))
    test "$rpushed" -eq (count $argv[2..])
end

function redfish-read --no-scope-shadowing --argument-names _redfish_var _redfish_key
    if test (count $argv) -ne 2
        return 1
    end

    set $_redfish_var
    if test "$(redfish-redis llen $_redfish_key)" -eq 0
        return
    end

    # Do not unescape the results as a whole to prevent values from
    # being split on newlines.
    for _redfish_value in (redfish-redis lrange $_redfish_key 0 -1)
        set --append $_redfish_var "$(string unescape $_redfish_value)"
    end

    set --erase _redfish_key _redfish_value _redfish_var
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
